/// 
Class CSVtoFHIR.BP.LabTestBatchProcess Extends Ens.BusinessProcess [ ClassType = persistent ]
{

/// 情報送付先コンポーネント名指定
Property TargetConfigName As %String(MAXLEN = 255);

/// FHIRエンドポイントのパスを指定します（必須）
Property FHIREndpoint As %String(MAXLEN = 512);

/// Patientリソースを検索するときのIdentifier.systemの値
Property IdentifierSystem As %String(MAXLEN = 512);

/// SETTINGSパラメータ
Parameter SETTINGS = "FHIREndpoint:CSVFHIR変換用設定:selector?context={HS.FHIRServer.Util.ContextSearch/FHIRServerEndpoints},TargetConfigName:CSVFHIR変換用設定:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},IdentifierSystem:CSVFHIR変換用設定";

Method OnRequest(pRequest As CSVtoFHIR.RM.LabTestBatch, Output pResponse As HS.FHIRServer.Interop.Response) As %Status
{
  #dim ex As %Exception.AbstractException
  set status=$$$OK
  try {
    set recordcnt=pRequest.Records.Count()
    set pidstring=""
		for i=1:1:recordcnt {
			set pid=pRequest.Records.GetAt(i).PatientId
			//新規のPIDか、すでに他の行で処理したPIDかチェックする
			if $Get(pidTemp("PatientMap",pid))'="Patient" {	
				set pidTemp("PatientMap",pid)="Patient"	
				set pidstring=pidstring_pid_","
			}
		}
    //患者名検索
    set searchRequest=##class(HS.FHIRServer.Interop.Request).%New()
    set searchRequest.Request.RequestMethod="GET"
    set searchRequest.Request.RequestPath="Patient"
    set searchRequest.Request.QueryString="identifier="_..IdentifierSystem_"|"_pidstring
    //set searchRequest.Request.QueryString="identifier="_..IdentifierSystem_"|"_pidstring_"&_pretty=true"
    set searchRequest.Request.RequestFormatCode="JSON"
    set searchRequest.Request.ResponseFormatCode="JSON"
    set searchRequest.Request.SessionApplication=..FHIREndpoint
    set searchRequest.Request.BaseURL=..FHIREndpoint
    #dim searchResponse As HS.FHIRServer.Interop.Response
    $$$ThrowOnError(..SendRequestSync(..TargetConfigName,searchRequest,.searchResponse))

    //検索エラーだった場合Catchへ移動
    if searchResponse.Response.Status'="200" {
    //ステータスエラーを作成してcatchへ移動
      set outcome=##class(HS.SDA3.QuickStream).%OpenId(searchResponse.QuickStreamId)
      throw ##class(%Exception.General).%New("FHIR OperationOutcome",,,outcome.Read())
    }
        
    //検索結果からPatientリソースを確認
    set searchResultQS=##class(HS.SDA3.QuickStream).%OpenId(searchResponse.QuickStreamId)
    //QuickStreamからJSONに変換
    set patJSON={}.%FromJSON(searchResultQS)

    if patJSON.total > 0 {
      //1件目の患者情報の内部IDを参照用に使う
      set iter=patJSON.entry.%GetIterator()
      while(iter.%GetNext(.key,.patient)) {
        set pid=patient.resource.identifier.%Get(0).value
        set pidTemp("PatientMap",pid)="Patient/"_patient.resource.id		
      }
    }
		set bundle=##class(FHIRCustom.BundleTransaction).%New()
			
		//Observationリソースに変換しBundleに格納する
		for i=1:1:recordcnt {
			//CSV入力のLabTest情報をFHIRのObservationリソースに変数するデータ変換を呼び出す
			$$$ThrowOnError(##class(CSVtoFHIR.Transform).Observation(pRequest.Records.GetAt(i),.observation,.pidTemp))
			
			// ObservationのHTTPメソッドをURLを指定
			set observation.requestMethod="POST"
			set observation.requestUrl="Observation"
			// BundleにObservationを登録
      do bundle.resource.Insert(observation)
      kill observation
		}
	
		$$$ThrowOnError(bundle.OutputToDynamicObject(.bundleJSON))

    $$$TRACE(bundleJSON.%ToJSON())
    //検証実行
    $$$ThrowOnError(##class(CSVtoFHIR.Utils).Validate(bundleJSON))

    //BundleをQuickStreamに登録
    set bundleQS=##class(HS.SDA3.QuickStream).%New()
    do bundleJSON.%ToJSON(bundleQS)
    //先頭ポジションに戻ります（必須）
    do bundleQS.Rewind()

    set fhirRequest=##class(HS.FHIRServer.Interop.Request).%New()
    set fhirRequest.Request.RequestMethod="POST"
    set fhirRequest.Request.RequestPath="/"
    set fhirRequest.Request.RequestFormatCode="JSON"
    set fhirRequest.Request.ResponseFormatCode="JSON"
    set fhirRequest.Request.SessionApplication=..FHIREndpoint
    set fhirRequest.Request.QueryString="_pretty=true"
    set fhirRequest.QuickStreamId=bundleQS.%Id()
    $$$ThrowOnError(..SendRequestSync(..TargetConfigName,fhirRequest,.pResponse))

    if pResponse.Response.Status'="200" {
    //ステータスエラーを作成してcatchへ移動
      set outcome=##class(HS.SDA3.QuickStream).%OpenId(pResponse.QuickStreamId)
      throw ##class(%Exception.General).%New("FHIR OperationOutcome",,,outcome.Read())
    }
  }
  catch ex {
    set status=ex.AsStatus()
  }
  return status
}

Storage Default
{
<Data name="LabTestBatchProcessDefaultData">
<Subscript>"LabTestBatchProcess"</Subscript>
<Value name="1">
<Value>TargetConfigName</Value>
</Value>
<Value name="2">
<Value>FHIREndpoint</Value>
</Value>
<Value name="3">
<Value>IdentifierSystem</Value>
</Value>
</Data>
<DefaultData>LabTestBatchProcessDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

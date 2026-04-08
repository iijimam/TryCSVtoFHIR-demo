/// 
Class CSVtoFHIR.BP.PatientProcess Extends Ens.BusinessProcess [ ClassType = persistent ]
{

/// 情報送付先コンポーネント名指定
Property TargetConfigName As %String(MAXLEN = 255);

/// FHIRエンドポイントのパスを指定します（必須）
Property FHIREndpoint As %String(MAXLEN = 512);

/// SETTINGSパラメータ
Parameter SETTINGS = "FHIREndpoint:CSVFHIR変換用設定:selector?context={HS.FHIRServer.Util.ContextSearch/FHIRServerEndpoints},TargetConfigName:CSVFHIR変換用設定:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Method OnRequest(pRequest As CSVtoFHIR.RM.Patient.Record, Output pResponse As HS.FHIRServer.Interop.Response) As %Status
{
    #dim ex As %Exception.AbstractException
    #dim patient As FHIRTemplate.Patient
    set status=$$$OK
    Try {
        //$$$ThrowOnError(##class(CSVtoFHIR.Transform).Patient(pRequest,.patient))
	      $$$ThrowOnError(##class(CSVtoFHIR.DTL.Patient).Transform(pRequest,.patient))

        $$$ThrowOnError(patient.OutputToDynamicObject(.patjson))

        //検証実行
        $$$ThrowOnError(##class(CSVtoFHIR.Utils).Validate(patjson))
        
        //QuickStreamに作成したPatientリソースを保存
        set QS=##class(HS.SDA3.QuickStream).%New()
        set quickStreamId=QS.%Id()
        //作成したPatientリソースをストリームに出力
        $$$ThrowOnError(patient.OutputToStream(QS))
	      //先頭ポジションに戻ります（必須）
        do QS.Rewind()

        set fhirRequest=##class(HS.FHIRServer.Interop.Request).%New()
        set fhirRequest.Request.RequestMethod="POST"
        set fhirRequest.Request.RequestPath="Patient"
        set fhirRequest.Request.RequestFormatCode="JSON"
        set fhirRequest.Request.ResponseFormatCode="JSON"
        set fhirRequest.Request.SessionApplication=..FHIREndpoint
        set fhirRequest.QuickStreamId=quickStreamId

        $$$ThrowOnError(..SendRequestSync(..TargetConfigName,fhirRequest,.pResponse))

        if pResponse.Response.Status'="201" {
			      //ステータスエラーを作成してcatchへ移動
            set outcome=##class(HS.SDA3.QuickStream).%OpenId(pResponse.QuickStreamId)
            throw ##class(%Exception.General).%New("FHIR OperationOutcome",,,outcome.Read())
        }
    }
    Catch ex {
        Set status=ex.AsStatus()
    }
    return status
}

Storage Default
{
<Data name="PatientProcessDefaultData">
<Subscript>"PatientProcess"</Subscript>
<Value name="1">
<Value>TargetConfigName</Value>
</Value>
<Value name="2">
<Value>FHIREndpoint</Value>
</Value>
</Data>
<DefaultData>PatientProcessDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

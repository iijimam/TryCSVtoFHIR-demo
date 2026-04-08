Class CSVtoFHIR.Transform
{

ClassMethod Patient(source As CSVtoFHIR.RM.Patient.Record, ByRef patient As FHIRTemplate.Patient) As %Status
{
    #dim ex As %Exception.AbstractException
    set status=$$$OK
    try {
        //レコードマップのインスタンスをJSONストリームに変換
        $$$ThrowOnError(source.%JSONExportToStream(.jstream))
        //JSONストリームからダイナミックオブジェクトに変換
        set in={}.%FromJSON(jstream.Read())
        set in.DOB=$ZDATEH(in.DOB,8)

        //FHIRTemplate.Patientのインスタンス生成時にデータ割り当て
        set patient=##class(FHIRTemplate.Patient).%New(in)
        //Patient.addressのAddressタイプにデータ割り当て
        set address=##class(FHIRTemplate.DataType.Address).%New(in)
        set patient.Address=address

		//GenderをFHIR R4 Patientリソースに合わせて変更
        set patient.Gender=$select(in.Gender="M":1,1:2)

    }
    catch ex {
        set status=ex.AsStatus()
    }
    return status
}

ClassMethod Observation(source As CSVtoFHIR.RM.LabTest.Record, ByRef observation As FHIRCustom.ObservationBodyMeasurement, ByRef aux As %String) As %Status
{
    #dim ex As %Exception.AbstractException
    set status=$$$OK
    Try {
        //レコードマップのインスタンスをJSONストリームに変換
        $$$ThrowOnError(source.%JSONExportToStream(.jstream))
        //JSONストリームからダイナミックオブジェクトに変換
        set in={}.%FromJSON(jstream.Read()) 

        //Obseration用テンプレートクラスのインスタンス生成
        set observation=##class(FHIRCustom.ObservationBodyMeasurement).%New()
   
        // Categoryの設定
        set category=##class(FHIRCustom.CodeableConcept.ObservationCategory).GetByCode("exam")
        do observation.Category.Insert(category)

        // Codeの作成
        set code=##class(FHIRCustom.CodeableConcept.BodyMeasurementCode).%New(in)
        set observation.Code=code
        
        // EffectiveDateTimeの設定
        set observation.EffectiveDateTime=$ZDATETIMEH(in.EffectiveDateTime,3)
        
        // valueQuantityの設定
        set valueQuantity=##class(FHIRTemplate.DataType.Quantity).%New(in)
        set observation.ValueQuantity=valueQuantity

        //reference（Observation.subjectにPatientのリソースIDをセット）
		if $get(aux("PatientMap",source.PatientId))'="" {
			set observation.PatientResourceId=aux("PatientMap",source.PatientId)
        }
		else {
			set observation.PatientResourceId="Patient/"_source.PatientId
		}
    }
    Catch ex {
        Set status=ex.AsStatus()
    }
    return status
}

}

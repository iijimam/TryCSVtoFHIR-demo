Class CSVtoFHIR.Utils Extends Ens.Rule.FunctionSet
{

/// in : データ変換後のJSON
ClassMethod Validate(in As %DynamicObject) As %Status
{
	#dim ex As %Exception.AbstractException
	set tSC=$$$OK
	try {
		set schema = ##class(HS.FHIRServer.Schema).LoadSchema("HL7v40")
		set resourceValidator = ##class(HS.FHIRServer.Util.ResourceValidator).%New(schema)
		do resourceValidator.ValidateResource(in) 
	}catch ex {
		set tSC=ex.AsStatus()
	}
	quit tSC
}

}

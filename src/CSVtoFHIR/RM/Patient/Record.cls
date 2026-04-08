/// THIS IS GENERATED CODE. DO NOT EDIT.<br/>
/// RECORDMAP: Generated from RecordMap 'CSVtoFHIR.RM.Patient'
/// on 2026-02-20 at 12:25:12.003 [2026-02-20 03:25:12.003 UTC]
/// by user SuperUser
Class CSVtoFHIR.RM.Patient.Record Extends (%Persistent, %XML.Adaptor, Ens.Request, EnsLib.RecordMap.Base, %JSON.Adaptor) [ Inheritance = right, ProcedureBlock ]
{

Parameter INCLUDETOPFIELDS = 1;

Property PatientId As %String [ SqlColumnNumber = 2 ];

Property HospitalID As %String [ SqlColumnNumber = 3 ];

Property LastName As %String [ SqlColumnNumber = 4 ];

Property FirstName As %String [ SqlColumnNumber = 5 ];

Property LastNameKana As %String [ SqlColumnNumber = 6 ];

Property FirstNameKana As %String [ SqlColumnNumber = 7 ];

Property DOB As %String [ SqlColumnNumber = 8 ];

Property Gender As %String [ SqlColumnNumber = 9 ];

Property postalCode As %String [ SqlColumnNumber = 10 ];

Property state As %String [ SqlColumnNumber = 11 ];

Property city As %String [ SqlColumnNumber = 12 ];

Property line As %String [ SqlColumnNumber = 13 ];

Property Phone As %String [ SqlColumnNumber = 14 ];

Parameter RECORDMAPGENERATED = 1;

Storage Default
{
<Data name="RecordDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PatientId</Value>
</Value>
<Value name="3">
<Value>%Source</Value>
</Value>
<Value name="4">
<Value>LastName</Value>
</Value>
<Value name="5">
<Value>FirstName</Value>
</Value>
<Value name="6">
<Value>LastNameKana</Value>
</Value>
<Value name="7">
<Value>FirstNameKana</Value>
</Value>
<Value name="8">
<Value>DOB</Value>
</Value>
<Value name="9">
<Value>Gender</Value>
</Value>
<Value name="10">
<Value>postalCode</Value>
</Value>
<Value name="11">
<Value>state</Value>
</Value>
<Value name="12">
<Value>city</Value>
</Value>
<Value name="13">
<Value>line</Value>
</Value>
<Value name="14">
<Value>Phone</Value>
</Value>
<Value name="15">
<Value>HospitalID</Value>
</Value>
</Data>
<DataLocation>^CSVtoFHIR.RM.Patient.RecordD</DataLocation>
<DefaultData>RecordDefaultData</DefaultData>
<IdLocation>^CSVtoFHIR.RM.Patient.RecordD</IdLocation>
<IndexLocation>^CSVtoFHIR.RM.Patient.RecordI</IndexLocation>
<StreamLocation>^CSVtoFHIR.RM.Patient.RecordS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

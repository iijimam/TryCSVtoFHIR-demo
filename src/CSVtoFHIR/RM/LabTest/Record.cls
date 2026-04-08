/// THIS IS GENERATED CODE. DO NOT EDIT.<br/>
/// RECORDMAP: Generated from RecordMap 'CSVtoFHIR.RM.LabTest'
/// on 2026-02-20 at 18:26:30.876 [2026-02-20 09:26:30.876 UTC]
/// by user SuperUser
Class CSVtoFHIR.RM.LabTest.Record Extends (%Persistent, %XML.Adaptor, Ens.Request, EnsLib.RecordMap.Base, %JSON.Adaptor) [ Inheritance = right, ProcedureBlock ]
{

Parameter INCLUDETOPFIELDS = 1;

Property PatientId As %String [ SqlColumnNumber = 2 ];

Property code As %String [ SqlColumnNumber = 3 ];

Property display As %String [ SqlColumnNumber = 4 ];

Property value As %String [ SqlColumnNumber = 5 ];

Property unit As %String [ SqlColumnNumber = 6 ];

Property EffectiveDateTime As %String [ SqlColumnNumber = 7 ];

Parameter RECORDMAPGENERATED = 1;

Relationship %ParentBatch As CSVtoFHIR.RM.LabTestBatch [ Cardinality = one, Inverse = Records ];

Index %ParentBatchIdx On %ParentBatch;

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
<Value>display</Value>
</Value>
<Value name="5">
<Value>value</Value>
</Value>
<Value name="6">
<Value>unit</Value>
</Value>
<Value name="7">
<Value>EffectiveDateTime</Value>
</Value>
<Value name="8">
<Value>%ParentBatch</Value>
</Value>
<Value name="9">
<Value>code</Value>
</Value>
</Data>
<DataLocation>^CSVtoFHIR.RM.LabTest.RecordD</DataLocation>
<DefaultData>RecordDefaultData</DefaultData>
<IdLocation>^CSVtoFHIR.RM.LabTest.RecordD</IdLocation>
<IndexLocation>^CSVtoFHIR.RM.LabTest.RecordI</IndexLocation>
<StreamLocation>^CSVtoFHIR.RM.LabTest.RecordS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

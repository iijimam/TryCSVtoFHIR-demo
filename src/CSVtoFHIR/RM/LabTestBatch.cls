/// RECORDMAP: Modified during compilation of RecordMap 'CSVtoFHIR.RM.LabTest'
/// on 2024-02-06 at 13:55:35.393 [2024-02-06 04:55:35.393 UTC]
/// by user SuperUser
Class CSVtoFHIR.RM.LabTestBatch Extends (%Library.Persistent, EnsLib.RecordMap.SimpleBatch)
{

Parameter XMLNAME = "CSVtoFHIR_RM_LabTestBatch";

Parameter RECORDMAPGENERATED = 1;

Parameter BatchHeader;

Parameter HeaderTerm;

Parameter BatchTrailer;

Parameter TrailerTerm;

Parameter IgnoreLeadingData = 0;

Relationship Records As CSVtoFHIR.RM.LabTest.Record [ Cardinality = many, Inverse = %ParentBatch ];

Trigger OnDelete [ Event = DELETE ]
{
	Set %ok = ..deleteRecords({ID})
}

Parameter XMLTYPE = "CSVtoFHIR_RM_LabTestBatch";

Storage Default
{
<Data name="LabTestBatchDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>%Source</Value>
</Value>
<Value name="3">
<Value>BatchHeader</Value>
</Value>
<Value name="4">
<Value>BatchTrailer</Value>
</Value>
</Data>
<DataLocation>^CSVtoFHIR.RM.LabTestBatchD</DataLocation>
<DefaultData>LabTestBatchDefaultData</DefaultData>
<IdLocation>^CSVtoFHIR.RM.LabTestBatchD</IdLocation>
<IndexLocation>^CSVtoFHIR.RM.LabTestBatchI</IndexLocation>
<StreamLocation>^CSVtoFHIR.RM.LabTestBatchS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

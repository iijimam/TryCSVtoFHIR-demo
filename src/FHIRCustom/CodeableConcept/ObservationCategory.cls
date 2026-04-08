Class FHIRCustom.CodeableConcept.ObservationCategory Extends (%Persistent, FHIRTemplate.Util.CodeTable, FHIRTemplate.DataType.CodeableConceptBase)
{

Parameter CodeSystem = "http://jpfhir.jp/fhir/Common/ValueSet/bodyMeasurement-code";

Index IDKeyIdx On code [ IdKey, Unique ];

/// コードは以下PDFを参考にしています。
/// https://std.jpfhir.jp/stddoc/eDischargeSummaryFHIR_v1x.pdf
XData InsertCode [ MimeType = application/json ]
{
{ "data":[
    "social-history;社会生活歴",
    "vital-signs;バイタルサイン",
    "imaging;画像検査",
    "laboratory;検査室検査",
    "survey;調査・評価",
    "exam;身体検査・観察",
    "therapy;非介入治療による観察結果",
    "activity;身体活動記録"
  ] 
}
}

Storage Default
{
<Data name="ObservationCategoryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>display</Value>
</Value>
</Data>
<DataLocation>^FHIRCustomC353.Observation2BCAD</DataLocation>
<DefaultData>ObservationCategoryDefaultData</DefaultData>
<ExtentSize>8</ExtentSize>
<IdLocation>^FHIRCustomC353.Observation2BCAD</IdLocation>
<IndexLocation>^FHIRCustomC353.Observation2BCAI</IndexLocation>
<Property name="%%CLASSNAME">
<AverageFieldSize>2</AverageFieldSize>
<OutlierSelectivity>.999999:</OutlierSelectivity>
<Selectivity>0.0001%</Selectivity>
</Property>
<Property name="%%ID">
<AverageFieldSize>10.38</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="code">
<AverageFieldSize>10.38</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="display">
<AverageFieldSize>14.75</AverageFieldSize>
<Selectivity>12.5000%</Selectivity>
</Property>
<SQLMap name="IDKeyIdx">
<BlockCount>-4</BlockCount>
</SQLMap>
<StreamLocation>^FHIRCustomC353.Observation2BCAS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

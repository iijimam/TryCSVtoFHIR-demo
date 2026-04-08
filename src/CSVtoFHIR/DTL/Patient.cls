Class CSVtoFHIR.DTL.Patient Extends Ens.DataTransformDTL [ DependsOn = (CSVtoFHIR.RM.Patient.Record, FHIRTemplate.Patient) ]
{

Parameter IGNOREMISSINGSOURCE = 1;

Parameter REPORTERRORS = 1;

Parameter TREATEMPTYREPEATINGFIELDASNULL = 0;

XData DTL [ XMLNamespace = "http://www.intersystems.com/dtl" ]
{
<transform sourceClass='CSVtoFHIR.RM.Patient.Record' targetClass='FHIRTemplate.Patient' create='new' language='objectscript' >
<assign value='source.LastName' property='target.LastName' action='set' />
<assign value='source.FirstName' property='target.FirstName' action='set' />
<assign value='source.LastNameKana' property='target.LastNameKana' action='set' />
<assign value='source.FirstNameKana' property='target.FirstNameKana' action='set' />
<assign value='$ZDATEH(source.DOB,8)' property='target.DOB' action='set' />
<assign value='$select(source.Gender="M":1,1:2)' property='target.Gender' action='set' />
<assign value='source.Phone' property='target.Phone' action='set' />
<assign value='source.PatientId' property='target.PatientId' action='set' />
<assign value='source.postalCode' property='target.Address.postalCode' action='set' />
<assign value='source.state' property='target.Address.state' action='set' />
<assign value='source.city' property='target.Address.city' action='set' />
<assign value='source.line' property='target.Address.line' action='set' />
</transform>
}

}

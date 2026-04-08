Class CSVtoFHIR.Production Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="CSVtoFHIR.Production" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="HS.Util.Trace.Operations" Category="" ClassName="HS.Util.Trace.Operations" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="HS.FHIRServer.Interop.Operation" Category="" ClassName="HS.FHIRServer.Interop.Operation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TraceOperations">*FULL*</Setting>
  </Item>
  <Item Name="CSVtoFHIR.BP.PatientProcess" Category="" ClassName="CSVtoFHIR.BP.PatientProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="FHIREndpoint">/csp/healthshare/r4fhirnamespace/fhir/r4</Setting>
    <Setting Target="Host" Name="TargetConfigName">HS.FHIRServer.Interop.Operation</Setting>
  </Item>
  <Item Name="CSVPatient" Category="" ClassName="EnsLib.RecordMap.Service.FileService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="RecordMap">CSVtoFHIR.RM.Patient</Setting>
    <Setting Target="Host" Name="TargetConfigNames">CSVtoFHIR.BP.PatientProcess</Setting>
    <Setting Target="Adapter" Name="FilePath">/data/in/</Setting>
    <Setting Target="Adapter" Name="Charset">Native</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.csv</Setting>
  </Item>
  <Item Name="CSVtoFHIR.BP.LabTestBatchProcess" Category="" ClassName="CSVtoFHIR.BP.LabTestBatchProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="FHIREndpoint">/csp/healthshare/r4fhirnamespace/fhir/r4</Setting>
    <Setting Target="Host" Name="IdentifierSystem">urn:oid:1.2.392.100495.20.3.51.11311234567</Setting>
    <Setting Target="Host" Name="TargetConfigName">HS.FHIRServer.Interop.Operation</Setting>
  </Item>
  <Item Name="CSVLabTest" Category="" ClassName="EnsLib.RecordMap.Service.BatchFileService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="BatchClass">CSVtoFHIR.RM.LabTestBatch</Setting>
    <Setting Target="Host" Name="BatchHandling">Whole</Setting>
    <Setting Target="Host" Name="RecordMap">CSVtoFHIR.RM.LabTest</Setting>
    <Setting Target="Host" Name="TargetConfigNames">CSVtoFHIR.BP.LabTestBatchProcess</Setting>
    <Setting Target="Adapter" Name="Charset">Native</Setting>
    <Setting Target="Adapter" Name="FilePath">/data/LabTestIn/</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.csv</Setting>
  </Item>
  <Item Name="PatientProcess-EmbeddedPython" Category="" ClassName="CSVtoFHIR.EP.BP.PatientProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="FHIREndpoint">/csp/healthshare/r4fhirnamespace/fhir/r4</Setting>
    <Setting Target="Host" Name="TargetConfigName">HS.FHIRServer.Interop.Operation</Setting>
  </Item>
  <Item Name="LabTestBatchProcess-EmbeddedPython" Category="" ClassName="CSVtoFHIR.EP.BP.LabTestBatchProcess" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="FHIREndpoint">/csp/healthshare/r4fhirnamespace/fhir/r4</Setting>
    <Setting Target="Host" Name="TargetConfigName">HS.FHIRServer.Interop.Operation</Setting>
    <Setting Target="Host" Name="IdentifierSystem">urn:oid:1.2.392.100495.20.3.51.11311234567</Setting>
  </Item>
</Production>
}

}

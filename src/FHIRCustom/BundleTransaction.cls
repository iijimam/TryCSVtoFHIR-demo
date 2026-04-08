Class FHIRCustom.BundleTransaction Extends FHIRTemplate.Bundle
{

/// type=transaction
XData Template [ MimeType = application/json ]
{
{
  "resourceType": "#(..#ResourceType)#",
  "type": "transaction",
  "entry": [
  	"#(..resource(FHIRTemplate.Bundle.entry))#"
  	]
}
}

}

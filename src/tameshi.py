import iris

def test(oref):
    print(oref.P1)

def test2():
    fhirrequest=iris.HS.FHIRServer.Interop.Request._New()
    fhirrequest.Request.RequestMethod="POST"
    fhirrequest.Request.RequestPath="Patient"
    fhirrequest.Request.RequestFormatCode="JSON"
    fhirrequest.Request.ResponseFormatCode="JSON"
    return "a", fhirrequest

def test3(array):
    print(array)
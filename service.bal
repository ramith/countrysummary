import ballerina/http;
import ballerina/mime;

type Country record {
    string code;
    string name;
    int population;
    decimal[] coordinates;
    string flagPic;
    string flag;
};

http:Client flagEndpoint = check new ("https://flagcdn.com");
http:Client countryEndpoint = check new ("https://restcountries.com/");

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    resource function get country/[string code](http:Request request) returns Country|error? {

        record {
            string cca2;
            int population;
            decimal[] latlng;
            string flag;
            record {
                string common;
            } name;


        }[] res = check countryEndpoint->get(string `v3.1/alpha/${code}`);

        if res.length() > 0 {
            Country country = {
                code: res[0].cca2,
                name: res[0].name.common,
                coordinates: res[0].latlng,
                population: res[0].population,
                flagPic: string`/country/${res[0].cca2.toLowerAscii()}/flag`,
                flag: res[0].flag
            };
            return country;
        }

        return error("unable to find the country", countrycode = code);
    }

    resource function get country/[string code]/flag(http:Request request, http:Caller caller) returns error? {
        byte[]|error content = getFlag(code);
        http:Response response = new ();

        if content is error {
            response.statusCode = http:STATUS_INTERNAL_SERVER_ERROR;
            response.setTextPayload(content.message(), mime:TEXT_PLAIN);
        } else {
            response.statusCode = http:STATUS_OK;
            response.setBinaryPayload(content, mime:IMAGE_PNG);

        }

        check caller->respond(response);
    }

}

function getFlag(string countryCode) returns byte[]|error {
    http:Response res = check flagEndpoint->get("/80x60/" + countryCode + ".png");
    return check res.getBinaryPayload();
}

public with sharing class Toggl {
    
    private Http h;
    private String apiKey;
    private Integer workspaceId;

    public Toggl(String apiKey, Integer workspaceId) {
        this.apiKey = apiKey;
        this.workspaceId = workspaceId;
    }

    public List<TogglProject> getProjects() {
    	return (List<TogglProject>)JSON.deserialize(
    		get('https://www.toggl.com/api/v8/workspaces/'+this.workspaceId+'/projects?').getBody(), 
    		List<TogglProject>.class
    	);
    }

    // helpers

    private class HttpException extends Exception {}

    private HttpResponse get(String url) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setHeader('Connection', 'keep-alive');
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(this.apiKey + ':api_token')));
        req.setEndpoint(url);
        if (h == null) {
            h = new Http();
        }
        HttpResponse res = h.send(req);
        if (res.getStatusCode() != 200) {
            throw new HttpException('Invalid status code ' + res.getStatusCode() + ' for ' + url);
        }
        return res;
    }

    // deserialization classes

    public class TogglProject {
        Integer id;
        Integer wid;
        Integer cid;
        String name;
        Boolean billable;
        Boolean is_private;
        Boolean active;
        Datetime at;
        Boolean template;
        Integer color;
    }
}

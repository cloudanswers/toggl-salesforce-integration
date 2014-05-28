public with sharing class Toggl {
    
    private Http h;
    private String apiKey;
    private Integer workspaceId;

    public Toggl(String apiKey, Integer workspaceId) {
        this.apiKey = apiKey;
        this.workspaceId = workspaceId;
    }

    public List<TogglClient> getClients() {
    	return (List<TogglClient>)JSON.deserialize(
    		get('https://www.toggl.com/api/v8/workspaces/'+this.workspaceId+'/clients').getBody(), 
    		List<TogglClient>.class
    	);
    }

    public List<TogglUser> getUsers() {
    	return (List<TogglUser>)JSON.deserialize(
    		get('https://www.toggl.com/api/v8/workspaces/'+this.workspaceId+'/users').getBody(), 
    		List<TogglUser>.class
    	);
    }

    public List<TogglProject> getProjects() {
    	return (List<TogglProject>)JSON.deserialize(
    		get('https://www.toggl.com/api/v8/workspaces/'+this.workspaceId+'/projects').getBody(), 
    		List<TogglProject>.class
    	);
    }

    public TogglDetailedReportResult getTimeEntries() {
        String url = 'https://www.toggl.com/reports/api/v2/details?user_agent=toggl_at_ccp.io&workspace_id='+this.workspaceId+'';
        TogglDetailedReportResult res = (TogglDetailedReportResult)JSON.deserialize(
            get(url).getBody(), 
            TogglDetailedReportResult.class
        );
        res.baseUrl = url;
        res.t = this;
        return res;
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

    public class TogglClient {
    	Integer id;
        Integer wid;
        String name;
        Datetime at;
        String notes;
        Integer hrate;
        String cur;
    }

    public class TogglUser {
    	Integer id;
        String email;
        String fullname;
        String image_url;
        Datetime at;
        Datetime created_at;
    }

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

    public class TogglDetailedReportResult {
        String baseUrl = '';
        Integer total_grand;
        Integer total_billable;
        Integer total_count;
        Integer page = 1;
        Integer per_page;
        List<TogglTimeEntry> data;
        Toggl t;
        public TogglDetailedReportResult next() {
            TogglDetailedReportResult res = (TogglDetailedReportResult)JSON.deserialize(
                t.get(baseUrl + '&page=' + (page + 1)).getBody(), 
                TogglDetailedReportResult.class
            );
            res.page = page + 1;
            res.baseUrl = baseUrl;
            res.t = t;
            return res;
        }
    }

    public class TogglTimeEntry {
        Integer id;
        Integer pid;
        Integer tid;
        Integer uid;
        String description;
        Datetime start;
        // reserved word "end" Datetime end;
        Datetime updated;
        Integer dur;
        String user;
        Boolean use_stop;
        String client;
        String project;
        String task;
        Decimal billable;
        Boolean is_billable;
        String cur;
        List<String> tags;
    }
}
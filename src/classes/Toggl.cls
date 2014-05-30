global with sharing class Toggl {
    
    private String apiKey;
    private Integer workspaceId;

    public Toggl(String apiKey, Integer workspaceId) {
        this.apiKey = apiKey;
        this.workspaceId = workspaceId;
    }

    public List<TogglClient> getClients() {
    	return (List<TogglClient>)JSON.deserialize(
    		get('https://www.toggl.com/api/v8/workspaces/'+this.workspaceId+'/clients'), 
    		List<TogglClient>.class
    	);
    }

    public List<TogglUser> getUsers() {
    	return (List<TogglUser>)JSON.deserialize(
    		get('https://www.toggl.com/api/v8/workspaces/'+this.workspaceId+'/users'), 
    		List<TogglUser>.class
    	);
    }

    public List<TogglProject> getProjects() {
    	return (List<TogglProject>)JSON.deserialize(
    		get('https://www.toggl.com/api/v8/workspaces/'+this.workspaceId+'/projects'), 
    		List<TogglProject>.class
    	);
    }

    public TogglDetailedReportResult getTimeEntries() {
        String url = 'https://www.toggl.com/reports/api/v2/details?user_agent=toggl_at_ccp.io&workspace_id='+this.workspaceId+'';
        TogglDetailedReportResult res = (TogglDetailedReportResult)JSON.deserialize(
            get(url), 
            TogglDetailedReportResult.class
        );
        res.baseUrl = url;
        res.page = 1;
        res.t = this;
        return res;
    }

    // helpers

    private class HttpException extends Exception {}

    @TestVisible
    private String getOverride;

    private String get(String url) {
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setHeader('Connection', 'keep-alive');
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(this.apiKey + ':api_token')));
        req.setEndpoint(url);
        Http h = new Http();
        if (getOverride != null) {
            return getOverride;
        }
        HttpResponse res = h.send(req);
        if (res.getStatusCode() != 200) {
            throw new HttpException('Invalid status code ' + res.getStatusCode() + ' for ' + url);
        }
        return res.getBody();
    }

    // deserialization classes

    public class TogglClient {
    	public Integer id;
        public Integer wid;
        public String name;
        public Datetime at;
        public String notes;
        public Integer hrate;
        public String cur;
        public Account toSObject() {
            return new Account(
                Toggl_ID__c = id,
                Name = name
            );
        }
    }

    public class TogglUser {
    	public Integer id;
        public String email;
        public String fullname;
        public String image_url;
        public Datetime at;
        public Datetime created_at;
        public Toggl_User__c toSObject() {
            return new Toggl_User__c(
                Toggl_ID__c = id,
                Name = fullname
            );
        }
    }

    public class TogglProject {
        public Integer id;
        public Integer wid;
        public Integer cid;
        public String name;
        public Boolean billable;
        public Boolean is_private;
        public Boolean active;
        public Datetime at;
        public Boolean template;
        public Integer color;
        public Toggl_Project__c toSObject() {
            return new Toggl_Project__c(
                Toggl_ID__c = id,
                Name = name,
                Account__r = new Account(Toggl_ID__c=cid)
            );
        }
    }

    public class TogglDetailedReportResult {
        public String baseUrl = '';
        public Integer total_grand;
        public Integer total_billable;
        public Integer total_count;
        public Integer page = 1;
        public Integer per_page;
        public List<TogglTimeEntry> data;
        public Toggl t;
        public TogglDetailedReportResult next() {
            TogglDetailedReportResult res = (TogglDetailedReportResult)JSON.deserialize(
                t.get(baseUrl + '&page=' + (page + 1)), 
                TogglDetailedReportResult.class
            );
            res.page = page + 1;
            res.baseUrl = baseUrl;
            res.t = t;
            return res;
        }
    }

    public class TogglTimeEntry {
        public Integer id;
        public Integer pid;
        public Integer tid;
        public Integer uid;
        public String description;
        public Datetime start;
        // reserved word "end" public Datetime end;
        public Datetime updated;
        public Integer dur;
        public String user;
        public Boolean use_stop;
        public String client;
        public String project;
        public String task;
        public Decimal billable;
        public Boolean is_billable;
        public String cur;
        public List<String> tags;
        public Toggl_Time_Entry__c toSObject() {
            return new Toggl_Time_Entry__c(
                Toggl_ID__c = id,
                Name = description,
                Toggl_User__r = new Toggl_User__c(Toggl_ID__c=uid),
                Toggl_Project__r = new Toggl_Project__c(Toggl_ID__c=pid),
                Timer_Start__c = start,
                Full_Description__c = description,
                Toggl_Updated__c = updated,
                Duration__c = dur == null ? null : dur/1000
            );
        }
    }
}
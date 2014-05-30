global class TogglSyncScheduler implements Schedulable {
	global void execute(SchedulableContext sc) {
		for (Toggl__c config : [select API_Token__c, Workspace_ID__c from Toggl__c]) {
			Toggl t = new Toggl(config.API_Token__c, (Integer)config.Workspace_ID__c);
			TogglSync b = new TogglSync(t);
			Database.executebatch(b);
		}
	}
}
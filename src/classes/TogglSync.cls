global class TogglSync implements Database.Batchable<String>, Database.Stateful {
	
	List<String> actions = new List<String>{
		'users',
		'clients',
		'projects',
		'time_entries'
	};

	Toggl toggl;
	Toggl.TogglDetailedReportResult currentTimeEntryReportResult;
	
	global TogglSync() {
		for(Integer i=0; i<20; i++) {
			actions.add(actions[actions.size()-1]);
		}
	}
	
	global List<String> start(Database.BatchableContext BC) {
		return actions;
	}

   	global void execute(Database.BatchableContext BC, List<String> scope) {
   		for (String s : scope) {
   			processScope(s);
   		}
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}

	// helpers

	private void processScope(String scope) {
		if (scope == 'users') {
			List<Toggl_User__c> users = new List<Toggl_User__c>();
			for (Toggl.TogglUser tobj : toggl.getUsers()) {
				users.add(tobj.toSObject());
			}
			// FIXME handle results
			Database.upsert(users, Toggl_User__c.Toggl_ID__c, false);
		} else if (scope == 'clients') {
			List<Account> accounts = new List<Account>();
			for (Toggl.TogglClient tobj : toggl.getClients()) {
				accounts.add(tobj.toSObject());
			}
			// FIXME handle results
			Database.upsert(accounts, Account.Toggl_ID__c, false);
		} else if (scope == 'projects') {
			List<Toggl_Project__c> projects = new List<Toggl_Project__c>();
			for (Toggl.TogglProject tobj : toggl.getProjects()) {
				projects.add(tobj.toSObject());
			}
			// FIXME handle results
			Database.upsert(projects, Toggl_Project__c.Toggl_ID__c, false);
		} else if (scope == 'time_entries') {
			List<Toggl_Time_Entry__c> timeEntries = new List<Toggl_Time_Entry__c>();
			currentTimeEntryReportResult = toggl.getTimeEntries();
			for (Toggl.TogglTimeEntry tobj : currentTimeEntryReportResult.data) {
				timeEntries.add(tobj.toSObject());
			}
			// FIXME handle results
			Database.upsert(timeEntries, Toggl_Time_Entry__c.Toggl_ID__c, false);
		}
	}
}
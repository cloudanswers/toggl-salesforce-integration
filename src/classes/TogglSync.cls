global class TogglSync implements Database.Batchable<String>, Database.Stateful {
	
	public List<String> actions = new List<String>{
		'users',
		'clients',
		'projects',
		'time_entries'
	};

	public Toggl toggl;
	public Toggl.TogglDetailedReportResult currentTimeEntryReportResult;
	public Boolean timeEntriesFinished = false;

	@TestVisible
	private Boolean didScheduleAdditionalBatch;
	
	global TogglSync(Toggl toggl) {
		this.toggl = toggl;
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
		if (!timeEntriesFinished) {
			TogglSync b = new TogglSync(toggl);
			b.actions = actions.clone();
			// remove the sync actions not related to the time entries
			// because only time_entries can be continued
			while (b.actions.get(0) != 'time_entries') {
				b.actions.remove(0);
			}
			// double the number of time entries that we want to process for next time
			b.actions.addAll(b.actions);
			b.currentTimeEntryReportResult = currentTimeEntryReportResult;

			if (Test.isRunningTest()) {
				didScheduleAdditionalBatch = true;
			} else {
				// WARNING should only do batch size of 10 so we stay under 
				// the per transaction govorner for callouts
				Database.executeBatch(b, 10);
			}
		}
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
			timeEntriesFinished = timeEntries.isEmpty();
			// FIXME handle results
			Database.upsert(timeEntries, Toggl_Time_Entry__c.Toggl_ID__c, false);
		}
	}
}
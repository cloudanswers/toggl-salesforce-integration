global class TogglSync implements Database.Batchable<String>, Database.Stateful, Database.AllowsCallouts {
	
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

			// stop out of control batches
			if (actions.size() > 100) {
				return;
			}

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
		List<Toggl_User__c> users = new List<Toggl_User__c>();
		List<Account> accounts = new List<Account>();
		List<Toggl_Project__c> projects = new List<Toggl_Project__c>();
		List<Toggl_Time_Entry__c> timeEntries = new List<Toggl_Time_Entry__c>();
		if (scope == 'users') {
			for (Toggl.TogglUser tobj : toggl.getUsers()) {
				users.add(tobj.toSObject());
			}
		} else if (scope == 'clients') {
			for (Toggl.TogglClient tobj : toggl.getClients()) {
				accounts.add(tobj.toSObject());
			}
		} else if (scope == 'projects') {
			for (Toggl.TogglProject tobj : toggl.getProjects()) {
				projects.add(tobj.toSObject());
			}
		} else if (scope == 'time_entries') {
			currentTimeEntryReportResult = toggl.getTimeEntries();
			for (Toggl.TogglTimeEntry tobj : currentTimeEntryReportResult.data) {
				timeEntries.add(tobj.toSObject());
			}
			timeEntriesFinished = timeEntries.isEmpty();
		}
		// TODO handle results
		Database.upsert(users, Toggl_User__c.Toggl_ID__c, false);
		Database.upsert(accounts, Account.Toggl_ID__c, false);
		Database.upsert(projects, Toggl_Project__c.Toggl_ID__c, false);
		Database.upsert(timeEntries, Toggl_Time_Entry__c.Toggl_ID__c, false);
	}
}
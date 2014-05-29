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
	public List<String> errors = new List<String>();
    @TestVisible
	private Boolean didScheduleAdditionalBatch;
	private Database.DMLOptions dmo;
    
    // --- buffers

    List<Toggl_User__c> users = new List<Toggl_User__c>();
    List<Account> accounts = new List<Account>();
    List<Toggl_Project__c> projects = new List<Toggl_Project__c>();
    List<Toggl_Time_Entry__c> timeEntries = new List<Toggl_Time_Entry__c>();

    // --- batch methods

	global TogglSync(Toggl toggl) {
        dmo = new Database.DMLOptions();
        dmo.allowFieldTruncation = true;
		this.toggl = toggl;
		while (actions.size() < 10) {
			actions.add(actions[actions.size()-1]);
		}
	}
	
	global List<String> start(Database.BatchableContext BC) {
		return actions;
	}

   	global void execute(Database.BatchableContext BC, List<String> scope) {
   		try {
	   		processScope(scope);
	   		processUpsertResults(users, Database.upsert(users, Toggl_User__c.Toggl_ID__c, false));
            processUpsertResults(accounts, Database.upsert(accounts, Account.Toggl_ID__c, false));
            processUpsertResults(projects, Database.upsert(projects, Toggl_Project__c.Toggl_ID__c, false));
            processUpsertResults(timeEntries, Database.upsert(timeEntries, Toggl_Time_Entry__c.Toggl_ID__c, false));
	   	} catch (Exception e) {
	   		errors.add(e.getMessage());
	   	}
	}
	
	global void finish(Database.BatchableContext BC) {
        if (timeEntriesFinished || actions.size() >= 50) {
            sendErrorEmail();
        } else {
			TogglSync b = new TogglSync(toggl);
			b.actions = actions.clone();
			// remove the sync actions not related to the time entries
			// because only time_entries can be continued
			while (b.actions.get(0) != 'time_entries') {
				b.actions.remove(0);
			}
			// double the number of time entries that we want to process for next time
			b.actions.addAll(actions);
			b.currentTimeEntryReportResult = currentTimeEntryReportResult;
            b.errors = errors;

            if (Test.isRunningTest()) {
				didScheduleAdditionalBatch = true;
			} else {
				// WARNING should only do batch size of 10 so we stay under 
				// the per transaction govorner for callouts
				Database.executeBatch(b, 10);
			}
		}
	}

	// --- helpers

    private void sendErrorEmail() {
        // if we have errors, stop scheduling new ones
        if (!errors.isEmpty()) {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{UserInfo.getUserEmail()});
            mail.setReplyTo(UserInfo.getUserEmail());
            mail.setSenderDisplayName('Toggl Salesforce Sync');
            mail.setSubject('Toggl Salesforce Sync Errors');
            String body = 'Errors: ';
            for (String e : errors) {
                body += '\n - ' + e;
            }
            mail.setPlainTextBody(body);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            return;
        }
    }

	public void processScope(List<String> scope) {
        for (String s : scope) {
    		if (s == 'users') {
    			for (Toggl.TogglUser tobj : toggl.getUsers()) {
    				users.add(tobj.toSObject());
                    users[users.size()-1].setOptions(dmo);
    			}
    		} else if (s == 'clients') {
    			for (Toggl.TogglClient tobj : toggl.getClients()) {
    				accounts.add(tobj.toSObject());
                    accounts[accounts.size()-1].setOptions(dmo);
    			}
    		} else if (s == 'projects') {
    			for (Toggl.TogglProject tobj : toggl.getProjects()) {
    				projects.add(tobj.toSObject());
                    projects[projects.size()-1].setOptions(dmo);
    			}
    		} else if (s == 'time_entries') {
    			currentTimeEntryReportResult = toggl.getTimeEntries();
    			for (Toggl.TogglTimeEntry tobj : currentTimeEntryReportResult.data) {
    				timeEntries.add(tobj.toSObject());
                    timeEntries[timeEntries.size()-1].setOptions(dmo);
    			}
    			timeEntriesFinished = timeEntries.isEmpty();
    		}
        }
	}

    private void processUpsertResults(List<SObject> sobjs, List<Database.UpsertResult> upsertResults) {
        for (Database.UpsertResult r : upsertResults) {
            if (!r.isSuccess()) {
                errors.add('' + r.getErrors());
            }
        }
    }
}
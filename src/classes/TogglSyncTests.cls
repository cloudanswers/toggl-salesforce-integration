@isTest
private class TogglSyncTests {
	
	@isTest static void itShouldContinueIfNotFinished() {
		Toggl t = new Toggl('test', 123);
		TogglSync s = new TogglSync(t);
		s.actions = new List<String>{'time_entries'};
		s.finish(null);
		System.assert(s.didScheduleAdditionalBatch);
	}

	@isTest static void itShouldNotContinueIfFinished() {
		Toggl t = new Toggl('test', 123);
		TogglSync s = new TogglSync(t);
		s.timeEntriesFinished = true;
		s.finish(null);
		System.assert(s.didScheduleAdditionalBatch != true);
	}
	
	@isTest static void itShouldHaveExecuteCoverage() {
		Toggl t = new Toggl('test', 123);
		t.getOverride = '[{}]';
		TogglSync s = new TogglSync(t);
		s.actions.remove(s.actions.size()-1); // take off time entries because incompatible with []
		s.execute(null, s.actions);
	}

	@isTest static void itShouldEmailOnParseError() {
		Toggl t = new Toggl('test', 123);
		t.getOverride = '[{}]';
		TogglSync s = new TogglSync(t);
		s.execute(null, new List<String>{'time_entries'});
		s.finish(null);
	}
}
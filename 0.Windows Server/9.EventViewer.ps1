# Event Viewer 로그 초기화 스크립트 
Wevtutil el | ForEach { wevtutil cl “$_”}

# 최근 10개의 시스템 에러 로그 확인 
Get-EventLog -LogName System -EntryType Error -Newest 10 | Select-Object TimeGenerated, Source, EventID, Message | Format-List

# 최근 10개의 시스템 경고 로그 확인 
Get-EventLog -LogName System -EntryType Warning -Newest 10 | Select-Object TimeGenerated, Source, EventID, Message | Format-List

# 최근 10개의 응용 프로그램 에러 로그 확인 
Get-EventLog -LogName Application -EntryType Error -Newest 10 | Select-Object TimeGenerated, Source, EventID, Message | Format-List

# 최근 10개의 보안 감사 실패 로그 확인 
Get-EventLog -LogName Security -EntryType FailureAudit -Newest 10 | Select-Object TimeGenerated, Source, EventID, Message | Format-List

# 최근 10개의 보안 감사 성공 로그 확인 
Get-EventLog -LogName Security -EntryType SuccessAudit -Newest 10 | Select-Object TimeGenerated, Source, EventID, Message | Format-List

import os
import re
from tqdm import tqdm

root_directory = "/home/sithlord/Downloads/Prod"
# define the patterns to search for and their replacements
name_pattern = (
r"\b((?!(?:jira|issueviews|http|dev|status|remote|event|update|summary|automation|ServerPluginLifeCycle|searchrequest|server|ServiceDeskUpgradeTaskFactory|upgrade|bootstrap|xml|IssueNavigator|SearchRequest|RapidBoard|jsp|default|"
r"jspa|Jql|Dashboard|high|svg|Tests|osd|config|json|versions|confluenceknowledgebase|PORTAL|ID|non|null|kblink|servicedesk|ViewProfile|lifecycle|internal|MyJiraHome|ManageRapidViews|"
r"cannedresponses|index|CannedResponseIndexLauncherImpl|feature|customer|request|re-sort|RequestListSearchQueryFactoryImpl|list|rule|executor|thread|CLUSTER_MESSAGE|SlaDataManagerImpl|data|sla|"
r"nio|exec|AFGIMSSD|Caesium|concurrent|db|dbcp|editor|startheartbeatactivity|scriptrunner|createpagetemplate|resumedraft|atlassian|catalina|awt|java|sidebar|common|ForkJoinPool|session|pubsub|entity|Function|"
r"jdk|currentNode|CodeSmells|synchrony|version|HazelcastInstance|confluence|custom|doeditattachment|viewpageattachments|manifold|clojure|aleph|ginga|org|com|rome|application|bnd|editattachment|"
r"ProviderManager|letterhead|line|movepage|user|path|os|file|jnidispatch|stash|bitbucket|jna|uploadpack|atl|batch|form|table|package|hundreds|writes|reads|requests|ics|debug|setup|messages|rrd4j|"
r"loader|jar|history|org|log|sh|groovy|model|mil|net|pdf|io|ico|png|jpeg|enabled|disabled|run|call|Incorrect|md|main|info|ConsistencyTask|task|BaseAppLinkResponseHandler|api|applink|"
r"searcher|sorter|sort|RemainingTimeOrderingIndexData|rest|CustomerWebResource|RemainingTimeSorter|order-by|sla.searcher.sorter.RemainingTimeSorter|com.atlassian.servicedesk.internal.sla.searcher.sorter.RemainingTimeOrderingIndexData|"
r"jira-stats|JiraStats|INDEXING-LIMITS|Deflater|ensureOpen|writer|LocalQCacheManager|localq|stats|ISSUE|CHANGE_HISTORY|cluster|auth|VIA|INVALIDATION|replicatePutsViaCopy|"
r"distrubution|NonAliveNodesScannerService|service|OfflineNodesScannerService|rmi|ClusterAuthStatsManager|AUTH|JIRA|STATS|ip|address|compute|west|gov|us|vendor|url|framework|projects|plugin|application|software|"
r"consumer|my|home|creation|modules|languages|zh|CN|analytics|client|node|count|com|oauth|tac|en|US|project|Analyzer|helptips|help|tips|nav|links|ro|RO|issue|web|www|translations|embedded|admin|sk|SK|"
r"analyzer|REL|Ltd|Adaptavist|ical|feed|extra|dnd|attachment|announcements|postsetup|streams|actions|es|ES|sv|SE|integration|scala|provider|workfloweditor|tabs|transition|extensions|runtime|Client|side|"
r"crowd|core|link|whisper|message|projectroleactors|system|keyboard|shortcuts|onresolve|groovy|groovyrunner|adaptavist|password|policy|apache|httpcomponents|httpclient|springsource|sun|syndication|"
r"atst|cs|CZ|keplerrominfo|warden|appfire|gadgets|serviceprovider|querydsl|plugins|fi|FI|pocketknife|commons|ja|JP|botronsoft|cmj|spi|bundle|it|IT|pl|PL|frontend|webpack|da|DK|de|DE|email|processor|"
r"preset|filters|webfragments|statistics|JohnsonHttpRequestHandlerServlet|HomeLockAcquirer|home|DefaultHookService|hook|SecretScanningWiring|DefaultMeshSidebandRegistry|DbCachingRemoteDirectory|"
r"InvalidCrowdServiceException|RestExecutor|executeCrowdServiceMethod|andReceive|searchUsers|directory|ldap|cache|RemoteDirectoryCacheRefresher|findAllRemoteUsers|synchroniseAllUsers|synchroniseAll|"
r"AbstractCacheRefresher|EventTokenChangedCacheRefresher|synchroniseCache|DirectorySynchroniserImpl|lambda|withAuditLogSource|NoOpAuditLogContext|manager|synchronise|invoke0|invoke|reflect|NativeMethodAccessorImpl|"
r"DelegatingMethodAccessorImpl|DbCachingDirectoryPoller|pollChanges|DirectoryPollerJobRunner|runJob|monitor|JobLauncher|core|spring|startup|MethodExecutor|RestCrowdClient|audit|bes|cce|af|mil|start|index|"
r"poller|launchJob|executeClusteredJob|executeClusteredJobWithRecoveryGuard|scheduler|caesium|impl|SchedulerQueueWorker|executeNextJob|executeJob|lang|Thread|max|results|exception|RemoteCrowdDirectory|"
r"synchronisation|resolution|usersync|NotificationRestResource|getAllNotifications|javax|Response|TestConnectorRestResource|HttpServletRequest|reconfigure|InsufficientUserPrivilegeException|"
r"secretscanning|maxsecrets|"
r"QuickSearch|ConfigurePortalPages|PortfolioRoadmapConfluence|ConfluenceKBLinkQStore|EditProfile))([A-Za-z]+[._-][A-Za-z0-9]+(?:[._-][A-Za-z0-9]+)*)\b(?!\d))"
)
name_replacement = "REDACTED"
ipv4_pattern = r"\b([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\b"
ipv4_replacement = "***.***.***.***"
aws_ipv4_pattern = r"ip-\d{1,3}-\d{1,3}-\d{1,3}-\d{1,3}"
aws_ipv4_replacement = "***-***-***-***"
#comma_separated_ipv4_pattern = r"([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})(?=,|$)"
#comma_separated_ipv4_replacement = "***.***.***.***"
def custom_name_replacer(match):
    matched_string = match.group(0)
    if matched_string in ignored_strings:
        return matched_string
    return name_replacement

ignored_strings = [
    "c.a.j.s.w.c.s.JohnsonHttpRequestHandlerServlet", "c.a.b.i.b.BitbucketServerApplication", "c.a.b.i.boot.log.BuildInfoLogger", "c.a.s.i.s.g.m.DefaultSidecarManager", "c.a.s.i.hook.DefaultHookService", "c.a.s.i.s.SecretScanningWiring",
    "c.a.s.internal.home.HomeLockAcquirer", "c.a.j.util.stats.JiraStats", "c.a.s.i.s.g.m.DefaultMeshSidebandRegistry", "c.a.c.d.DbCachingRemoteDirectory", "c.a.c.d.DbCachingDirectoryPoller", "o.e.g.b.e.i.s.ExtenderConfiguration"
]


filename_pattern = re.compile(r"\.(csv|log|xml)(\.[1-9])?(?:\d{4}-\d{2}-\d{2})?$")

for subdir, dirs, files in os.walk(root_directory):
    for filename in tqdm(files, desc="Processing files"):
        if filename_pattern.search(filename):
            with open(os.path.join(subdir, filename), "r", encoding="utf-8") as input_file:
                file_contents = input_file.read()

                # replace occurrences of the name pattern in the file contents using the custom replacer
                file_contents = re.sub(name_pattern, custom_name_replacer, file_contents)

                # replace all occurrences of the IPv4 pattern in the file contents
                file_contents = re.sub(ipv4_pattern, ipv4_replacement, file_contents)
                
                # replace all occurrences of the AWS IPv4 pattern in the file contents
                file_contents = re.sub(aws_ipv4_pattern, aws_ipv4_replacement, file_contents)

            with open(os.path.join(subdir, f"redacted_{filename}"), "w", encoding="utf-8") as output_file:
                output_file.write(file_contents)
                
            os.remove(os.path.join(subdir, filename))
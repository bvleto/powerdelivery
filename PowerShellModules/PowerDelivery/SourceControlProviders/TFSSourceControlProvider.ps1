function Initialize-TFSSourceControlProvider {
  
  # TODO: Lookup WorkspaceName, get BuildUri from buildparams, RequestedBy from buildparams, ChangeSet from buildparams

  if ($powerdelivery.onServer) {

      #Require-NonNullField -variable $changeSet -errorMsg "-changeSet parameter is required when running on TFS"
      #Require-NonNullField -variable $requestedBy -errorMsg "-requestedBy parameter is required when running on TFS"
      #Require-NonNullField -variable $buildUri -errorMsg "-buildUri parameter is required when running on TFS"
      #Require-NonNullField -variable $dropLocation -errorMsg "-dropLocation parameter is required when running on TFS"
      
      if ($powerdelivery.environment -ne "Local") {

        $teamProject = $powerdelivery.sourceControl.Parameters['TeamProject'];
        if ([String]::IsNullOrWhitespace($teamProject)) {
          throw "The TeamProject parameter is missing from SourceControl configuration for TFS"
        }

        $workspaceName = $powerdelivery.sourceControl.Parameters['WorkspaceName'];
        if ([String]::IsNullOrWhitespace($workspaceName)) {
          throw "The WorkspaceName parameter is missing from SourceControl configuration for TFS"
        }

        $collectionUri = $powerdelivery.sourceControl.Parameters['CollectionUri'];
        if ([String]::IsNullOrWhitespace($collectionUri)) {
          throw "The CollectionUri parameter is missing from SourceControl configuration for TFS"
        }

        $buildUri = $powerdelivery.sourceControl.Parameters['BuildUri'];
        if ([String]::IsNullOrWhitespace($buildUri)) {
          throw "The BuildUri parameter is missing from SourceControl configuration for TFS"
        }

        LoadTFS
        
        $powerdelivery.collection = [Microsoft.TeamFoundation.Client.TfsTeamProjectCollectionFactory]::GetTeamProjectCollection($collectionUri)
        $powerdelivery.buildServer = $powerdelivery.collection.GetService([Microsoft.TeamFoundation.Build.Client.IBuildServer])
        $powerdelivery.structure = $powerdelivery.collection.GetService([Microsoft.TeamFoundation.Server.ICommonStructureService])
        
        $buildServerVersion = $powerdelivery.buildServer.BuildServerVersion
        
        if ($buildServerVersion -eq 'v3') {
          $powerdelivery.tfsVersion = '2010'
        }
        elseif ($buildServerVersion -eq 'v4') {
          $powerdelivery.tfsVersion = '2012'
        }
        else {
          throw "TFS server must be version 2010 or 2012, a different version was detected."
        }

        $powerdelivery.projectInfo = $powerdelivery.structure.GetProjectFromName($teamProject)
        if (!$powerdelivery.projectInfo) {
          throw "Project '$teamProject' not found in TFS collection '$collectionUri'"
        }
        
        $powerdelivery.groupSecurity = $powerdelivery.collection.GetService([Microsoft.TeamFoundation.Server.IGroupSecurityService])
        $powerdelivery.appGroups = $powerdelivery.groupSecurity.ListApplicationGroups($powerdelivery.projectInfo.Uri)
      }
    }
    else {
      $powerdelivery.requestedBy = whoami
    }
}
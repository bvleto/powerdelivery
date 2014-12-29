param(
  [string] $action = "compile"
)

function NewDocsPage($title, $content)
{
@"
<!DOCTYPE html>
<html>
    <head>
        <meta charset='utf-8'>
        <meta http-equiv='X-UA-Compatible' content='IE=edge'>
        <meta http-equiv='content-type' content='text/html; charset=UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1'>
        <title>$titlePrefix - $title</title>
        <link href='https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.1/css/bootstrap.min.css' rel='stylesheet' charset='utf-8'>
        <link href='https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.1/css/bootstrap-theme.min.css' rel='stylesheet' charset='utf-8'>
        <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
        <!--[if lt IE 9]>
          <script src='http://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js'></script>
          <script src='http://oss.maxcdn.com/respond/1.4.2/respond.min.js'></script>
        <![endif]-->
    </head>
    <body>
        <div class='container'>
            <h1>$title</h1>
            $content
        </div>
        <script src='http://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js' charset='utf-8'></script>
        <script src='https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.1/js/bootstrap.min.js' charset='utf-8'></script>
    </body>
</html>
"@    
}

Write-Host "Performing a [$action] build from powerdelivery source..."

$titlePrefix = 'PowerDelivery PowerShell Reference'

$curDir = Get-Location

try
{
  switch ($action)
  {
    'compile'
    {

    }
    'docs'
    {
      $titlePrefix = 'PowerDelivery PowerShell Reference'

      Import-Module powerdelivery -force

      $docsPath = Join-Path $curDir Docs

      Remove-Item -Recurse -Path $docsPath -Force -ErrorAction SilentlyContinue | Out-Null

      Write-Host "Creating $docsPath..."

      New-Item -ItemType Directory -Path $docsPath | Out-Null

      #
      # Document module
      #

      $functionsPath = Join-Path $docsPath functions
      New-Item -ItemType Directory -Path $functionsPath | Out-Null

      $exportedFunctionLinks = (get-module powerdelivery).ExportedCommands.Keys | % { 
      @"
      <li>
          <a href='functions/$($_.ToLower().Replace(':', '_')).html'>$_</a>
      </li>
"@
    }

      NewDocsPage -title $titlePrefix -content @"
      <ul class='nav nav-pills nav-stacked'>
          $exportedFunctionLinks
      </ul>
"@ | Out-File -FilePath (Join-Path $docsPath "index.html")

      #
      # Document functions
      #
      (get-module powerdelivery).ExportedCommands.Values | % { 
          Write-Host "Creating $(Join-Path $functionsPath $_.Name).html..."
          NewDocsPage -title $_.Name -content @"
          <p><a href='../index.html'>&lt;&lt; Back to module reference</a></p>
          <pre>$(Get-Help $_.Name -Full | out-string)</pre>
"@ | Out-File -FilePath (Join-Path $functionsPath "$($_.Name.ToLower().Replace(':', '_')).html")
      }
    }
    'test'
    {
      Set-Location .\Tests
      Import-Module Pester
      Invoke-Pester
    }
  }
}
finally {
  Set-Location $curDir
}
﻿$powerYamlModule = Join-Path (Get-Location) "..\PowerShellModules\PowerYaml\PowerYaml.psm1"
Import-Module $powerYamlModule -Force

$srcModule = Join-Path (Get-Location) "..\PowerShellModules\Powerdelivery\PowerDelivery.psd1"
Import-Module $srcModule -Force

Set-Location TestPipelines
$curDir = Get-Location

Describe "Invoke-PowerDelivery" {
  It "should require -buildScript parameter" {
    try
    {
      {
        Set-Location Blank
        Invoke-PowerDelivery
      } | Should Throw "The -buildScript parameter is required."
    }
    finally
    {
      Set-Location $curDir
    }
  }
  It "should fail with nonexistent build script" {
    try
    {
      {
        Set-Location Blank
        Invoke-PowerDelivery .\BlankPipeline.ps1
      } | Should Throw "The build script .\BlankPipeline.ps1 does not exist."
    }
    finally
    {
      Set-Location $curDir
    }
  }
  It "should fail with missing current config file" {
    try
    {
      {
        Set-Location Blank_Missing_Current_Config
        Invoke-PowerDelivery .\Blank.ps1
      } | Should Throw "Build configuration file BlankLocal.yml not found."
    }
    finally
    {
      Set-Location $curDir
    }
  }
  It "should fail with missing shared config file" {
    try
    {
      {
        Set-Location Blank_Missing_Shared_Config
        Invoke-PowerDelivery .\Blank.ps1
      } | Should Throw "Build configuration file BlankShared.yml not found."
    }
    finally
    {
      Set-Location $curDir
    }
  }
  It "should fail with missing source control config" {
    try
    {
      {
        Set-Location Blank_Missing_Source_Control
        Invoke-PowerDelivery .\Blank.ps1
      } | Should Throw "SourceControl configuration missing from .yml files."
    }
    finally
    {
      Set-Location $curDir
    }
  }
  It "should succeed with minimal config and fileset" {
    try
    {
      Set-Location Blank
      Invoke-PowerDelivery .\Blank.ps1
    }
    finally
    {
      Set-Location $curDir
    }
  }
}
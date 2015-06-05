<#
.Synopsis
    Download all linked files on a webpage
.DESCRIPTION
    Scrapes a webpage for links which look like files, i.e. links that end with what appears to be a file extension.
    The URL should be specified using the -URL parameter.
    An output directory can be optionally specified, if not specified then the current working directory is used to store downloaded files.
.EXAMPLE
    Get-AllFilesFromUrl -URL "http://www.somewebpage.tld" -outputDirectory C:\Temp
.Outputs
    Files
.NOTES
    Robert D. Biddle 6.05.2015
.FUNCTIONALITY
    Allows the downloading of a list of files from a webpage to be downloaded programatically without needing to know the names of the files.
#>
Param(
    [OutputType([System.IO.File])]
    [parameter(Mandatory=$True)]
    [String]
    $URL,
    [parameter(Mandatory=$False)]
    [String]
    $outputDirectory
    )
Begin
{
    [regex]$regexLookForExtension = '(\.(\w){3}$)' # Matches URLs which end with something that looks like a file extension (e.g. .exe) 
    [regex]$regexAfterLastSlash = '[^/]*$' # Matches everthing after the last / 

    If(!$outputDirectory){$outputDirectory = ".\"}
    Set-Location $outputDirectory
    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
}
Process
{
    $page = Invoke-WebRequest -Uri $URL -SessionVariable $cookie
    $downloadLink = ($page.ParsedHtml.IHTMLDocument2_links | Where {$regexLookForExtension.Matches($_.href)} | select href)
    Write-Output $downloadLink.href
    If((Test-Path $outputDirectory) -ne $True)
        {
        New-Item -ItemType Directory -Name $outputDirectory
        }
    foreach ($link in $downloadLink.href)
    {
        $fileToDownload = $($regexAfterLastSlash.Matches($link).Value)
        if($regexLookForExtension.Matches($link).Success -ne $True){continue}
        if((Test-Path "$($outputDirectory)$($fileToDownload)") -eq $True){continue}
        Write-Output "Downloading file: $fileToDownload From Link: $link"
        Invoke-WebRequest -Uri $link -SessionVariable $cookie -OutFile "$fileToDownload" -UseBasicParsing
    }
}

$CountyUrl = 'https://www.hostelworld.com/hostels/oceania/new-zealand/'
$currency = 'NZD'

# prepare RAW-Run folder and write marker file
$workspace = (Get-Location)
$rawRunRel   = "raw/"
$rawRunRoot  = Join-Path $workspace $rawRunRel

if (-not (Test-Path -Path $rawRunRoot)) {
  New-Item -Path $rawRunRoot -ItemType Directory -Force | Out-Null
}

function Get-HostelworldApiKey
{
  $webClient = New-Object System.Net.WebClient
  $webClient.Encoding = [System.Text.Encoding]::UTF8
  $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0")
  $webClient.Headers.Add("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
  $webClient.Headers.Add("Accept-Language", "en-US,en;q=0.5")
  $webClient.Headers.Add("Sec-GPC", "1")
  $webClient.Headers.Add("Upgrade-Insecure-Requests", "1")
  $webClient.Headers.Add("Sec-Fetch-Dest", "document")
  $webClient.Headers.Add("Sec-Fetch-Mode", "navigate")
  $webClient.Headers.Add("Sec-Fetch-Site", "none")
  $webClient.Headers.Add("Sec-Fetch-User", "?1")
  $webClient.Headers.Add("Priority", "u=0, i")
  $webClient.Headers.Add("Pragma", "no-cache")
  $webClient.Headers.Add("Cache-Control", "no-cache")
  $webClient.Headers.Add("TE", "trailers")

  $content = $webClient.DownloadString("https://www.hostelworld.com/")

  $apiKey = $content
  $apiKey = $apiKey.Substring(($apiKey.IndexOf('APIGEE_KEY:"') + 12))
  $apiKey = $apiKey.Substring(0, ($apiKey.IndexOf('"')))
  
  return $apiKey
}

function Get-HostelworldCities
{
  [CmdletBinding()]
  param (
      [Parameter()]
      [String]
      $apiKey,

      [Parameter()]
      [String]
      $searchTerm = "auckland"
  )

  $restResult = Invoke-RestMethod -UseBasicParsing -Uri "https://prod.apigee.hostelworld.com/autocomplete-service/v1/autocomplete/web/?text=$searchTerm&v=variation" `
  -UserAgent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0" `
  -Headers @{
  "Accept" = "application/json"
    "Accept-Language" = "en"
    "Accept-Encoding" = "gzip, deflate, br, zstd"
    "Referer" = "https://www.hostelworld.com/"
    "api-key" = "$apiKey"
    "Origin" = "https://www.hostelworld.com"
    "Sec-GPC" = "1"
    "Sec-Fetch-Dest" = "empty"
    "Sec-Fetch-Mode" = "cors"
    "Sec-Fetch-Site" = "same-site"
    "x-flag-switch-db" = ""
    "Priority" = "u=4"
    "Pragma" = "no-cache"
    "Cache-Control" = "no-cache"
    "TE" = "trailers"
  } `
  -ContentType "application/json"

  return $restResult
}

function Get-HostelworldProperties
{
  [CmdletBinding()]
  param (
      [Parameter(Mandatory=$true)]
      [String]
      $cityId,

      [Parameter()]
      [String]
      $currency = "EUR",

      [Parameter(Mandatory=$true)]
      [DateTime]
      $dateStart,

      [Parameter()]
      [Int]
      $numNights = 5,

      [Parameter()]
      [Int]
      $guests = 1,

      [Parameter()]
      [Int]
      $perPage = 1000,

      [Parameter()]
      [Int]
      $showRooms = 1,

      [Parameter()]
      [Int]
      $propertyNumImages = 30
  )

  $dateStartString = $dateStart.ToString("yyyy-MM-dd")

  $restResult = Invoke-RestMethod -UseBasicParsing -Uri "https://prod.apigee.hostelworld.com/legacy-hwapi-service/2.2/cities/$cityId/properties/?currency=$currency&application=app&date-start=$dateStartString&num-nights=$numNights&guests=$guests&per-page=$perPage&show-rooms=$showRooms&property-num-images=$propertyNumImages&v=variation" `
  -UserAgent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0" `
  -Headers @{
  "Accept" = "application/json, text/plain, */*"
    "Accept-Language" = "en"
    "Accept-Encoding" = "gzip, deflate, br, zstd"
    "Sec-GPC" = "1"
    "Sec-Fetch-Dest" = "empty"
    "Sec-Fetch-Mode" = "cors"
    "Sec-Fetch-Site" = "same-site"
    "Pragma" = "no-cache"
    "Cache-Control" = "no-cache"
    "TE" = "trailers"
  }

  return $restResult
}

function Get-HostelworldProperty
{
  [CmdletBinding()]
  param (
      [Parameter(Mandatory=$true)]
      [String]
      $propertyId,

        [Parameter()]
        [String]
        $apiKey
  )

  $restResult = Invoke-RestMethod -UseBasicParsing -Uri "https://prod.apigee.hostelworld.com/legacy-msapi-service/property/$propertyId" `
    -UserAgent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:143.0) Gecko/20100101 Firefox/143.0" `
    -Headers @{
    "Accept" = "application/json, text/plain, */*"
    "Accept-Language" = "en"
    "Accept-Encoding" = "gzip, deflate, br, zstd"
    "api-key" = $apiKey
    "Origin" = "https://www.hostelworld.com"
    "Sec-Fetch-Dest" = "empty"
    "Sec-Fetch-Mode" = "cors"
    "Sec-Fetch-Site" = "same-site"
    "Priority" = "u=0"
    "Pragma" = "no-cache"
    "Cache-Control" = "no-cache"
    "TE" = "trailers"
    }

    return $restResult
}

function Get-HostelworldPropertyAvailability
{
  [CmdletBinding()]
  param (
      [Parameter(Mandatory=$true)]
      [String]
      $propertyId,

      [Parameter(Mandatory=$true)]
      [DateTime]
      $dateStart,

      [Parameter()]
      [Int]
      $numNights = 5,

      [Parameter()]
      [Int]
      $guests = 1,

      [Parameter()]
      [Bool]
      $showRateRestrictions = $true,

      [Parameter()]
      [String]
      $application = "web"
  )

  $dateStartString = $dateStart.ToString("yyyy-MM-dd")
  $showRateRestrictionsString = $showRateRestrictions.ToString().ToLower()

  $restResult = Invoke-RestMethod -UseBasicParsing -Uri "https://prod.apigee.hostelworld.com/legacy-hwapi-service/2.2/properties/$propertyId/availability/?guests=$guests&num-nights=$numNights&date-start=$dateStartString&show-rate-restrictions=$showRateRestrictionsString&application=$application" `
  -UserAgent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:142.0) Gecko/20100101 Firefox/142.0" `
  -Headers @{
  "Accept" = "application/json, text/plain, */*"
    "Accept-Language" = "en"
    "Accept-Encoding" = "gzip, deflate, br, zstd"
    "Sec-GPC" = "1"
    "Sec-Fetch-Dest" = "empty"
    "Sec-Fetch-Mode" = "cors"
    "Sec-Fetch-Site" = "same-site"
    "Pragma" = "no-cache"
    "Cache-Control" = "no-cache"
    "TE" = "trailers"
  }

  return $restResult
}

# getting api key
$apiKey = Get-HostelworldApiKey
Write-Host "Using api key: $apiKey"

$countryPageContent = Invoke-WebRequest -Uri $CountyUrl -UseBasicParsing
$countryPageContent = $countryPageContent.Content

#get all urls from content
$cityUrls = [regex]::Matches($countryPageContent, ('href="({0}[^/"]+/)" class="destination-card-wrapper"' -f $CountyUrl.Replace('.', '\.'))) | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique

$results = @(foreach($cityUrl in $cityUrls)
{
    Write-Host "City url: $cityUrl"
    $uri = [System.Uri]$cityUrl

    
    
    $citySearchTerm = $uri.Segments[-2].TrimEnd('/') + ' ' + $uri.Segments[-1].TrimEnd('/')
    Get-HostelworldCities -apiKey $apiKey -searchTerm $citySearchTerm | Where-Object {$_.type -eq "CITY"} | Select-Object -ExpandProperty id
}) | Select-Object -Unique

Write-Host "Found $($results.Count) unique city ids"

# foreach city id get property ids
$allPropertyIds = @()
foreach ($cityId in $results)
{
    $range = @(1, 5, 14, 30) # check these days for properties to find more properties
    foreach($date in $range)
    {
        $dateStart = (Get-Date).AddDays($date)
        Write-Host "Crawling city id $cityId for date $($dateStart.ToString("yyyy-MM-dd"))"
        try
        {
            $propertyResult = Get-HostelworldProperties -cityId $cityId -currency $currency -dateStart $dateStart -numNights 1 -guests 1
        }
        catch
        {
            Write-Host "    ! Error fetching properties for city $cityId on date $($dateStart.ToString("yyyy-MM-dd"))"
            continue
        }
        $propertyIds = $propertyResult.properties.id
        $allPropertyIds += $propertyIds
    }
}
$allPropertyIds = $allPropertyIds | Select-Object -Unique
Write-Host "Found $($allPropertyIds.Count) unique property ids"

# crawl room data for all property ids the next 90 days
foreach ($propertyId in $allPropertyIds)
{
    Write-Host "Crawling property id $propertyId"
    $crawledTime = Get-Date
    try 
    {
        $PropertyData = Get-HostelworldProperty -propertyId $propertyId -apiKey $apiKey
        $jsonPropPath = Join-Path $rawRunRoot $propertyId
        if(-not (Test-Path -Path $jsonPropPath)) { New-Item -Path $jsonPropPath -ItemType Directory -Force | Out-Null }
        $jsonFile = Join-Path $jsonPropPath ('{0}.json' -f ([DateTimeOffset]$crawledTime).ToUnixTimeSeconds())
        $PropertyData | ConvertTo-Json -Depth 99 -Compress | Out-File -FilePath $jsonFile -Encoding utf8
        $propertyHistoryFile = Join-Path -Path $workspace -ChildPath ("{0}_property_history.csv" -f $propertyId)
        $data2store = [PSCustomObject]@{
            propertyId    = $propertyId
            crawledAt     = ([DateTimeOffset]$crawledTime).ToUnixTimeSeconds()
            urlPart       = "$propertyId/$(([DateTimeOffset]$crawledTime).ToUnixTimeSeconds()).json"
        }
        $data2store | Export-Csv -Path $propertyHistoryFile -NoTypeInformation -Append
    }
    catch 
    {
        Write-Host "    ! Error fetching property data for property $propertyId"
    }
    
    $range = 0..30 # check the next 30 days for availability
    foreach($date in $range)
    {
        $dateStart = (Get-Date).AddDays($date)
        Write-Host "  - Crawling date $($dateStart.ToString("yyyy-MM-dd"))"
        try 
        {
            $availability = Get-HostelworldPropertyAvailability -propertyId $propertyId -dateStart $dateStart -numNights 1 -guests 1        
        }
        catch 
        {
            Write-Host "    ! Error fetching availability for property $propertyId on date $($dateStart.ToString("yyyy-MM-dd"))"
            continue
        }

        # write JSON to raw run folder
        $jsonPropPath = Join-Path $rawRunRoot $propertyId
        if(-not (Test-Path -Path $jsonPropPath)) { New-Item -Path $jsonPropPath -ItemType Directory -Force | Out-Null }
        $jsonDatePath = Join-Path $jsonPropPath ($dateStart.ToString("yyyy-MM-dd"))
        if(-not (Test-Path -Path $jsonDatePath)) { New-Item -Path $jsonDatePath -ItemType Directory -Force | Out-Null }
        $jsonFile = Join-Path $jsonDatePath ('{0}.json' -f ([DateTimeOffset]$crawledTime).ToUnixTimeSeconds())
        $availability | ConvertTo-Json -Depth 99 -Compress | Out-File -FilePath $jsonFile -Encoding utf8
        
        #urlPart raw-data/raw/100250/2025-10-04/1759577088.json
        $urlPart = "$propertyId/$($dateStart.ToString("yyyy-MM-dd"))/$(([DateTimeOffset]$crawledTime).ToUnixTimeSeconds()).json"

        # write price history to CSV
        if ($availability -and $availability.rooms -and $availability.rooms.dorms) {
            foreach($dorm in $availability.rooms.dorms)
            {
                $priceHistoryFile = Join-Path -Path $workspace -ChildPath ("{0}_prices_history.csv" -f $propertyId)
                foreach($priceBreakdown in $dorm.priceBreakdown)
                {
                    $data2store = [PSCustomObject]@{
                        dormId        = $dorm.id
                        ratePlan      = $priceBreakdown.ratePlan
                        date          = $priceBreakdown.date
                        priceValue    = $priceBreakdown.price.value
                        priceCurrency = $priceBreakdown.price.currency
                        crawledAt     = ([DateTimeOffset]$crawledTime).ToUnixTimeSeconds()
                        urlPart       = $urlPart
                    }
                    $data2store | Export-Csv -Path $priceHistoryFile -NoTypeInformation -Append
                }
            }
        }
    }
}

Write-Host "Crawling finished."

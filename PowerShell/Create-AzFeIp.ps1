<# Create-AzFeIp.ps1
Purpose:
    Create Azure Public LB IPs
Author:
    John McDonough (jmcdonough@fortinet.com) github: (@movinalot)
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,
    [Parameter(Mandatory=$false)]
    [String]
    $Location,
    [Parameter(Mandatory=$true)]
    [String]
    $LoadBalancerName,
    [Parameter(Mandatory=$false)]
    [Int]
    $NumIps=1,
    [Parameter(Mandatory=$false)]
    [Int]
    $StartIpNum=1,
    [Parameter(Mandatory=$false)]
    [String]
    $IpNamePrefix="fe-ip-"
)

$resourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
    Write-Error "Resource Group: $ResourceGroupName does not exist"
    Exit 1
}

$loadBalancer = Get-AzLoadBalancer -ResourceGroupName $ResourceGroupName -Name $LoadBalancerName -ErrorAction SilentlyContinue
if (!$loadBalancer) {
    Write-Error "Load Balancer: $LoadBalancerName does not exist in Resource Group: $ResourceGroupName"
    Exit 1
}

#check location valid
if (!$Location) {
    $Location = $resourceGroup.Location
}


$StartIpNum..($StartIpNum + $NumIps - 1) | ForEach-Object {
    $feIpAddress = Get-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $IpNamePrefix$_ -ErrorAction SilentlyContinue

    if (!$feIpAddress){
        $feIpAddress = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -Name $IpNamePrefix$_ -Sku Standard -AllocationMethod Static -WarningAction SilentlyContinue
        if ($feIpAddress) {
            $feIpAddressConfig = Add-AzLoadBalancerFrontendIpConfig -LoadBalancer $loadBalancer -Name $IpNamePrefix$_ -PublicIpAddress $feIpAddress | Set-AzLoadBalancer

            if ($feIpAddressConfig) {
                $feLbIpConfig = Get-AzLoadBalancerFrontendIpConfig -Name $IpNamePrefix$_ -LoadBalancer $loadBalancer
                if ($feLbIpConfig) {
                    Write-Output "Load Balancer FrontEnd IP Address: $IpNamePrefix$_ has been added to Load Balancer: $LoadBalancerName in Resource Group: $ResourceGroupName"
                }
            }
        }
    }
}

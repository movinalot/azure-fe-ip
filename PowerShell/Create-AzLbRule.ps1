<# Create-AzLbRule.ps1
Purpose:
    Create Azure Load Balancer Rules
Author:
    John McDonough (jmcdonough@fortinet.com) github: (@movinalot)
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String]
    $ResourceGroupName,
    [Parameter(Mandatory=$true)]
    [String]
    $LoadBalancerName,
    [Parameter(Mandatory=$true)]
    [String]
    $BackendAddressPoolName,
    [Parameter(Mandatory=$true)]
    [String]
    $LoadbalancerHealthProbeName,
    [Parameter(Mandatory=$true)]
    [String]
    $FrontEndIpConfigurationName,
    [Parameter(Mandatory=$true)]
    [Int]
    $FrontendPort,
    [Parameter(Mandatory=$true)]
    [Int]
    $BackendPort,
    [Parameter(Mandatory=$false)]
    [String]
    $LoadBalancerRuleName
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

$backendAddressPool = Get-AzLoadBalancerBackendAddressPool -ResourceGroupName $ResourceGroupName -LoadBalancerName $LoadBalancerName -Name $BackendAddressPoolName -ErrorAction SilentlyContinue
if (!$backendAddressPool) {
    Write-Error "Load Balancer Backend Address Pool: $BackendAddressPoolName does not exist with load balancer: $LoadBalancerName"
    Exit 1
}

$loadbalancerHealthProbe = Get-AzLoadBalancerProbeConfig -LoadBalancer $loadBalancer -Name $LoadbalancerHealthProbeName -ErrorAction SilentlyContinue
if (!$loadbalancerHealthProbe) {
    Write-Error "Load Balancer Health Probe: $LoadbalancerHealthProbeName does not exist with load balancer: $LoadBalancerName"
    Exit 1
}

$feLbIpConfig = Get-AzLoadBalancerFrontendIpConfig -Name $FrontEndIpConfigurationName -LoadBalancer $loadBalancer -ErrorAction SilentlyContinue
if (!$feLbIpConfig) {
    Write-Error "Load Balancer FrontEnd IP Configuration: $FrontEndIpConfigurationName does not exist with load balancer: $LoadBalancerName"
    Exit 1
}

$loadBalancerRule = Get-AzLoadBalancerRuleConfig -LoadBalancer $loadBalancer -Name $LoadBalancerRuleName -ErrorAction SilentlyContinue

if (!$loadBalancerRule -and $feLbIpConfig ){
    $loadBalancerRuleConfig = Add-AzLoadBalancerRuleConfig `
                                -LoadBalancer $loadBalancer `
                                -Name $LoadBalancerRuleName `
                                -Protocol $RuleProtocol `
                                -FrontendPort $FrontendPort `
                                -BackendPort $BackendPort `
                                -FrontendIpConfiguration $feLbIpConfig `
                                -BackendAddressPool $backendAddressPool `
                                -Probe $loadbalancerHealthProbe `
                                -ErrorAction SilentlyContinue | Set-AzLoadBalancer

    if (!$loadBalancerRuleConfig) {
        Write-Error -Message "Error"
        Exit 1
    }
}

#./Create-AzLbRule.ps1 -ResourceGroupName jmcdonough-ap-elb-ilb-az-eastus2-01 -LoadBalancerName APEASTUS201-ExternalLoadBalancer -BackendAddressPoolName APEASTUS201-ILB-ExternalSubnet-BackEnd -LoadbalancerHealthProbeName lbprobe -FrontEndIpConfigurationName fe-ip-1 -FrontendPort 80 -BackendPort 4080 -LoadBalancerRuleName  fe-ip-1-http
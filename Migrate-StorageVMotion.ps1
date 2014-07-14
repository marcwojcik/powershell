Connect-VIServer vcenter-prod
Get-VM "useomapd1217" |Move-VM -datastore (Get-datastore "Non-Production_EVC3_03_S_012")

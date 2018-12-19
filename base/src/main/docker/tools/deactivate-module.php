<?php
include_once "oxid-helper.inc.php";

$sModuleId = $argv[2];
$sShopId = $argv[3];

if (empty($sModuleId)) {
    exit("ModuleId empty");
}

if (empty($sShopId)) {
    exit("ShopId empty");
}

changeToShop($sShopId);

$sModulesDir = oxRegistry::getConfig()->getModulesDir();

$oModuleList = oxNew("oxModuleList");
$aModules = $oModuleList->getModulesFromDir($sModulesDir);

$count = 0;

foreach ($aModules as $oModule) {
    if (preg_match('#'.$sModuleId.'#', $oModule->getId())) {
        $count++;
        
        try {
            $oModuleCache = oxNew('oxModuleCache', $oModule);
            $oModuleInstaller = oxNew("oxModuleInstaller", $oModuleCache);
            
            if ($oModule->isActive()) {
                $oModuleInstaller->deactivate($oModule);
            }
        } catch (oxException $oEx) {
            exit($oEx->debugOut());
        }
    }
}

if($count == 0) {
    exit("No Module found.");
}
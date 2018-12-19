<?php
if (! empty($argv[1])) {
    require_once $argv[1] . "/bootstrap.php";
} else {
    require_once dirname(__FILE__) . "/../bootstrap.php";
}

function changeToShop($sShopId)
{
    foreach (oxRegistry::getKeys() as $sClassName) {
        if (! in_array($sClassName, array(
            'oxconfigfile'
        ))) {
            oxRegistry::set($sClassName, null);
        }
    }
    
    oxUtilsObject::getInstance()->resetModuleVars();
    oxUtilsObject::getInstance()->resetClassInstances();
    oxUtilsObject::getInstance()->resetInstanceCache();
    
    $_POST['shp'] = $sShopId;
    
    $myConfig = oxNew('oxconfig');
    $myConfig->setShopId($sShopId);
    $myConfig->init();
    
    oxRegistry::getConfig()->setConfig(null);
    oxRegistry::set('oxconfig', $myConfig);
}
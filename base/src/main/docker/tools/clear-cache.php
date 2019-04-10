<?php
include_once __DIR__ ."/oxid-helper.inc.php";

$oShopList = oxNew('oxShopList');
$oShopList->getAll();

foreach ($oShopList as $oSchop) {
    $sShopId = $oSchop->getId();
    
    changeToShop($sShopId);
    
    $oCache = oxNew('oxcache');
    $oCache->reset(false);
    
    oxRegistry::getUtils()->oxResetFileCache();
    
    $oRpBackend = oxRegistry::get('oxCacheBackend');
    $oRpBackend->flush();
}
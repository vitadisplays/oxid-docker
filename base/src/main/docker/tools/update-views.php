<?php
include_once "oxid-helper.inc.php";

$sShopId = $argv[2];

if (empty($sShopId)) {
    exit("ShopId empty");
}

changeToShop($sShopId);

$oMetaData = oxNew('oxDbMetaDataHandler');

if(!$oMetaData->updateViews()) {
    exit("updateViews failed");
}
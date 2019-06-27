<?php

include_once __DIR__ . "/oxid-helper.inc.php";

$sTheme = $argv[2];
$sShopId = $argv[3];

if (empty($sTheme)) {
    exit("ThemeId empty");
}

if (empty($sShopId)) {
    exit("ShopId empty");
}

changeToShop($sShopId);

activateTheme($sTheme);
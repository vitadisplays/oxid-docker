<?php

include_once __DIR__ ."/oxid-helper.inc.php";

$sFilename = $argv[2];

if (empty($sFilename)) {
    exit("Filename empty");
}

$aConfigs = null;
$content = file_get_contents($sFilename);

foreach ($_SERVER as $sKey => $sValue) {
    $aPattern[] = '${'.$sKey.'}';
    $aReplacements[] = $sValue;
}

$content = str_replace($aPattern, $aReplacements, $content);

switch(pathinfo($sFilename, PATHINFO_EXTENSION)) {
    case 'yml' : $aConfigs = yaml_parse($content); break;
    case 'json' : $aConfigs = json_decode($content, true); break;
    case 'ser' : unserialize($content); break;
    default: exit("Unkown File format $sFilename.");
}

$oConfig = new myConfig();

foreach($aConfigs as $aConfig) {
    $oConfig->saveShopConfVar(
        $aConfig['type'], 
        $aConfig['name'], 
        $aConfig['value'],
        isset($aConfig['shopid']) ? $aConfig['shopid'] : null, 
        isset($aConfig['module']) ? $aConfig['module'] : ''
    );
}
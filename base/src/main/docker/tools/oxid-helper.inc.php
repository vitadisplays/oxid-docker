<?php
define('OX_IS_ADMIN', true);
define('OX_ADMIN_DIR', basename(empty($argv[1]) ? dirname(__FILE__)."/../admin" : $argv[1] . "/admin"));

if (! empty($argv[1])) {
    require_once $argv[1] . "/bootstrap.php";
} else {
    require_once dirname(__FILE__) . "/../bootstrap.php";
}

require_once getShopBasePath() . '/core/adodblite/adodb.inc.php';

class myConfig
{
    protected $_oDb;
    
    public function __construct() {
        include getShopBasePath() . '/config.inc.php';
        include getShopBasePath() . '/core/oxconfk.php';
    }
    
    protected function _setUp($oDb)
    {
        $oDb->cacheSecs = 60 * 10; // 10 minute caching
        $oDb->execute('SET @@session.sql_mode = ""');
        
        if ($this->iUtfMode) {
            $oDb->execute('SET NAMES "utf8"');
            $oDb->execute('SET CHARACTER SET utf8');
            $oDb->execute('SET CHARACTER_SET_CONNECTION = utf8');
            $oDb->execute('SET CHARACTER_SET_DATABASE = utf8');
            $oDb->execute('SET character_set_results = utf8');
            $oDb->execute('SET character_set_server = utf8');
        }
    }
    
    protected function _getConnection() {
        if($this->_oDb == null) {
            $sHost = $this->dbHost;
            $sUser = $this->dbUser;
            $sPwd = $this->dbPwd;
            $sName = $this->dbName;
            $sType = $this->dbType;
            
            $this->_oDb = ADONewConnection($sType);
            
            $this->_oDb->nconnect($sHost, $sUser, $sPwd, $sName);
            
            $this->_setUp($this->_oDb);
        }
        
        return $this->_oDb;
    }
    
    public function saveShopConfVar($sVarType, $sVarName, $sVarVal, $sShopId = null, $sModule = '')
    {
        switch ($sVarType) {
            case 'arr':
            case 'aarr':
                $sValue = serialize($sVarVal);
                break;
            case 'bool':
                //config param
                $sVarVal = (($sVarVal == 'true' || $sVarVal) && $sVarVal && strcasecmp($sVarVal, "false"));
                //db value
                $sValue = $sVarVal ? "1" : "";
                break;
            case 'num':
                //config param
                $sVarVal = $sVarVal != '' ? oxRegistry::getUtils()->string2Float($sVarVal) : '';
                $sValue = $sVarVal;
                break;
            default:
                $sValue = $sVarVal;
                break;
        }
        
        if (!$sShopId) {
            $sShopId = 1;
        }
        
        $oDb = $this->_getConnection();
        $sShopIdQuoted = $oDb->quote($sShopId);
        $sModuleQuoted = $oDb->quote($sModule);
        $sVarNameQuoted = $oDb->quote($sVarName);
        $sVarTypeQuoted = $oDb->quote($sVarType);
        $sVarValueQuoted = $oDb->quote($sValue);
        $sConfigKeyQuoted = $oDb->quote($this->sConfigKey);
        $sNewOXIDdQuoted = $oDb->quote(oxUtilsObject::getInstance()->generateUID());
        
        $sQ = "delete from oxconfig where oxshopid = $sShopIdQuoted and oxvarname = $sVarNameQuoted and oxmodule = $sModuleQuoted";
        $oDb->execute($sQ);
        
        $sQ = "insert into oxconfig (oxid, oxshopid, oxmodule, oxvarname, oxvartype, oxvarvalue)
               values($sNewOXIDdQuoted, $sShopIdQuoted, $sModuleQuoted, $sVarNameQuoted, $sVarTypeQuoted, ENCODE( $sVarValueQuoted, $sConfigKeyQuoted) )";
        $oDb->execute($sQ);
    }
}

function changeToShop($sShopId)
{
    /*foreach (oxRegistry::getKeys() as $sClassName) {
        if (! in_array($sClassName, array(
            'oxconfigfile'
        ))) {
            oxRegistry::set($sClassName, null);
        }
    }
    
    oxUtilsObject::getInstance()->resetModuleVars();
    oxUtilsObject::getInstance()->resetClassInstances();
    oxUtilsObject::getInstance()->resetInstanceCache();*/
    
    $_POST['shp'] = $sShopId;
    
    /*$myConfig = new oxConfig();
    $myConfig->setShopId($sShopId);
    $myConfig->init();
    
    oxRegistry::getConfig()->setConfig(null);
    oxRegistry::set('oxconfig', $myConfig);*/
}

function resetContentCache()
{
    $blDeleteCacheOnLogout = oxRegistry::getConfig()->getConfigParam('blClearCacheOnLogout');
    
    if (! $blDeleteCacheOnLogout) {
        // reset output cache
        /** @var oxCache $oCache */
        $oCache = oxNew('oxcache');
        $oCache->reset(false);
        
        oxRegistry::getUtils()->oxResetFileCache();
    }
}

function activateTheme($sTheme)
{

    /** @var oxTheme $oTheme */
    $oTheme = oxNew('oxtheme');
    if (!$oTheme->load($sTheme)) {
        oxRegistry::get("oxUtilsView")->addErrorToDisplay(oxNew("oxException", 'EXCEPTION_THEME_NOT_LOADED'));
        
        return;
    }
    try {
        $oTheme->activate();
        resetContentCache();
    } catch (oxException $oEx) {
        oxRegistry::get("oxUtilsView")->addErrorToDisplay($oEx);
        $oEx->debugOut();
    }
}

function _updateOxTime($soxId)
{
    $oDb = oxDb::getDb();
    $sO2CView = getViewName('oxobject2category');
    $soxId = $oDb->quote($soxId);
    $sSqlShopFilter = "";
    $sShopId = oxRegistry::getConfig()->getShopId();
    $sSqlShopFilter = "and oxshopid = {$sShopId}";
    // updating oxtime values
    $sQ = "update oxobject2category set oxtime = 0 where oxobjectid = {$soxId} {$sSqlShopFilter} and oxid = (
                    select oxid from (
                        select oxid from {$sO2CView} where oxobjectid = {$soxId} {$sSqlShopFilter}
                        order by oxtime limit 1
                    ) as _tmp
                )";
    $oDb->execute($sQ);
}

function resetArtSeoUrl($aArtIds, $aCatIds = null)
{
    if (empty($aArtIds)) {
        return;
    }
    
    if (! is_array($aArtIds)) {
        $aArtIds = array(
            $aArtIds
        );
    }
    
    $sShopId = oxRegistry::getConfig()->getShopId();
    foreach ($aArtIds as $sArtId) {
        /** @var oxSeoEncoder $oSeoEncoder */
        oxRegistry::get("oxSeoEncoder")->markAsExpired($sArtId, $sShopId, 1, null, "oxtype='oxarticle'");
    }
}

function addArticleToCategory($sArticleId, $sCatId, $iPos = 0)
{
    $myConfig = oxRegistry::getConfig();
    $oDb = oxDb::getDb();
    $sO2CView = getViewName('oxobject2category');
    
    $sSelect = "select 1 from " . $sO2CView . " as oxobject2category where oxobject2category.oxcatnid= " . $oDb->quote($sCatId) . " and oxobject2category.oxobjectid = " . $oDb->quote($sArticleId) . " ";
    
    if (! $oDb->getOne($sSelect, false, false)) {
        $sShopID = $myConfig->getShopId();
        
        $oNew = oxNew('oxobject2category');
        $oNew->setId(md5($sArticleId . $sCatId . $sShopID));
        $oNew->oxobject2category__oxobjectid = new oxField($sArticleId);
        $oNew->oxobject2category__oxcatnid = new oxField($sCatId);
        $oNew->oxobject2category__oxtime = new oxField(time());
        $oNew->oxobject2category__oxpos = new oxField($iPos);
        
        $oNew->save();
        
        _updateOxTime($sArticleId);
        
        resetArtSeoUrl($sArticleId);
        resetContentCache();
        
        $oCategory = oxNew('oxCategory');
        $oCategory->executeDependencyEvent(array(
            $sCatId
        ));
        
        return true;
    }
    
    return false;
}
#include "QAmazonAds.h"
#include "s3eAmazonAds.h"
#include "s3eDevice.h"
#include "IwDebug.h"
#include "string.h"
#include "QLuaHelpers.h"

using namespace quick;

namespace amazonAds {

//---- Callbacks ----

int32 onAdLoad(void* systemData, void* userData)
{
    QTrace("amazonAds::onAdLoad");
    
    s3eAmazonAdsCallbackLoadedData* data = static_cast<s3eAmazonAdsCallbackLoadedData*>(systemData);

    if (data == NULL || data->m_Properties == NULL)
    {
        QTrace("onAdLoad error: callback data is NULL.");
        return 1;
    }

    LUA_EVENT_PREPARE("amazonAds"); //here we have "defined" an event called "amazonAds"
    //Chosen to have a single event for amazon ads and use "type" to switch
    //between the 3 callbacks. Keeps the API small/manageable
    LUA_EVENT_SET_STRING("type", "loaded");
    LUA_EVENT_SET_INTEGER("adId", data->m_Id);
    
    const char* type;
    if (data->m_Properties->m_AdType == S3E_AMAZONADS_TYPE_IMAGE_BANNER)
        type = "imageBanner";
    else if (data->m_Properties->m_AdType == S3E_AMAZONADS_TYPE_RICH_MEDIA_MRAID1)
        type = "richMediaMraid1";
    else if (data->m_Properties->m_AdType == S3E_AMAZONADS_TYPE_RICH_MEDIA_MRAID2)
        type = "richMediaMraid2";
    else if (data->m_Properties->m_AdType == S3E_AMAZONADS_TYPE_INTERSTITIAL)
        type = "interstitial";
    else
        type = "unknown";
    
    
    LUA_EVENT_SET_STRING("adType", type);
    LUA_EVENT_SET_BOOLEAN("canPlayAudio", data->m_Properties->m_CanPlayAudio);
    LUA_EVENT_SET_BOOLEAN("canPlayAudio", data->m_Properties->m_CanPlayVideo);
    LUA_EVENT_SET_BOOLEAN("canExpand", data->m_Properties->m_CanExpand);
    
    LUA_EVENT_SEND();
    
    return true;
}

int32 onAdAction(void* systemData, void* userData)
{
    QTrace("amazonAds::onAdAction");
    
    s3eAmazonAdsCallbackActionData* data = static_cast<s3eAmazonAdsCallbackActionData*>(systemData);

    if (data == NULL)
    {
        QTrace("onAdAction error: callback data is NULL.");
        return 1;
    }

    LUA_EVENT_PREPARE("amazonAds");
    LUA_EVENT_SET_STRING("type", "action");
    LUA_EVENT_SET_INTEGER("adId", data->m_Id);
    
    const char* type;
    if (data->m_Type == S3E_AMAZONADS_ACTION_EXPANDED)
        type = "expanded";
    else if (data->m_Type == S3E_AMAZONADS_ACTION_COLLAPSED)
        type = "collapsed";
    else
        type = "dismissed";
    
    LUA_EVENT_SET_STRING("actionType", type);
    
    LUA_EVENT_SEND();
    
    return true;
}

int32 onAdError(void* systemData, void* userData)
{
    QTrace("amazonAds::onAdError");
    
    s3eAmazonAdsCallbackErrorData* data = static_cast<s3eAmazonAdsCallbackErrorData*>(systemData);

    if (data == NULL)
    {
        QTrace("onAdError error: callback data is NULL.");
        return 1;
    }

    LUA_EVENT_PREPARE("amazonAds");
    LUA_EVENT_SET_STRING("type", "error");
    LUA_EVENT_SET_INTEGER("adId", data->m_Id);
    
    const char* error;
    if (data->m_Error == S3E_AMAZONADS_ERR_LOAD_NETWORK_ERROR)
        error = "networkError";
    else if (data->m_Error == S3E_AMAZONADS_ERR_LOAD_NETWORK_TIMEOUT)
        error = "networkTimeout";
    else if (data->m_Error == S3E_AMAZONADS_ERR_LOAD_NO_FILL)
        error = "noFill";
    else if (data->m_Error == S3E_AMAZONADS_ERR_LOAD_INTERNAL_ERROR)
        error = "internalError";
    else if (data->m_Error == S3E_AMAZONADS_ERR_LOAD_REQUEST_ERROR)
        error = "requestError";
    else
        error = "unknown";
    
    LUA_EVENT_SET_STRING("error", error);
    
    LUA_EVENT_SEND();
    
    return true;
}


//---- Public functions ----

bool isAvailable()
{
    return s3eAmazonAdsAvailable();
}

bool init(char* androidAppKey, char* iosAppKey, bool enableTesting, bool enableLogging, bool useEvents)
{
    //todo? might want a reloadAdOnSurfaceChange callback that asks for a new ad if there
    //is a rotation or resize event...
    
    bool initialised = false;
    
    if (s3eDeviceGetInt(S3E_DEVICE_OS) == S3E_OS_ID_ANDROID)
    {
        if (!androidAppKey || !androidAppKey[0]) return false;
		initialised = s3eAmazonAdsInit(androidAppKey, enableTesting, enableLogging) == S3E_RESULT_SUCCESS;
    }
	else if (s3eDeviceGetInt(S3E_DEVICE_OS) == S3E_OS_ID_IPHONE)
    {
        if (!iosAppKey || !iosAppKey[0]) return false;
		initialised = s3eAmazonAdsInit(iosAppKey, enableTesting, enableLogging) == S3E_RESULT_SUCCESS;
    }
    
    if (initialised && useEvents)
    {
        s3eAmazonAdsRegister(S3E_AMAZONADS_CALLBACK_AD_LOADED, onAdLoad,  NULL);
        s3eAmazonAdsRegister(S3E_AMAZONADS_CALLBACK_AD_ACTION, onAdAction, NULL);
        s3eAmazonAdsRegister(S3E_AMAZONADS_CALLBACK_AD_ERROR,  onAdError,  NULL);
    }
    
    return initialised;
}

bool terminate()
{
    return s3eAmazonAdsTerminate();
}

int prepareAd()
{
    s3eAmazonAdsId id =-1;
    if (s3eAmazonAdsPrepareAd(&id) == S3E_RESULT_SUCCESS)
        return (int)id;
    else
        return -1;
}

bool prepareAdLayout(int adId, char* position, char* size, int width, int height)
{
    s3eAmazonAdsPosition e_pos = S3E_AMAZONADS_POSITION_TOP;
    if (position && position[0])
    {
        if (strcmp(position, "bottom") == 0)
            e_pos = S3E_AMAZONADS_POSITION_BOTTOM;
        else if (strcmp(position, "top") != 0)
            IwAssert(AMAZON_ADS, (false, "prepareAdLayout value invalid, using default of 'top'"));
    }
    
    s3eAmazonAdsSize e_size = S3E_AMAZONADS_SIZE_AUTO;
    if (size && size[0])
    {
        if (strcmp(size, "custom") == 0 )
            e_size = S3E_AMAZONADS_SIZE_CUSTOM;
    }
    
    int w = 0;
    int h = 0;
    if (e_size == S3E_AMAZONADS_SIZE_CUSTOM)
    {
        if (width == 300 && height == 50)
            e_size = S3E_AMAZONADS_SIZE_300x50;
        if (width == 320 && height == 50)
            e_size = S3E_AMAZONADS_SIZE_320x50;
        if (width == 300 && height == 250)
            e_size = S3E_AMAZONADS_SIZE_300x250;
        if (width == 600 && height == 90)
            e_size = S3E_AMAZONADS_SIZE_600x90;
        if (width == 728 && height == 90)
            e_size = S3E_AMAZONADS_SIZE_728x90;
        if (width == 1024 && height == 50)
            e_size = S3E_AMAZONADS_SIZE_1024x50;
        else
        {
            w = width;
            h = height;
        }
    }
    
    return s3eAmazonAdsPrepareAdLayout(adId, e_pos, e_size, w, h) == S3E_RESULT_SUCCESS;
}

bool loadAd(int adId, bool show, float timeout)
{
    return s3eAmazonAdsLoadAd(adId, show, (int)(timeout*1000)) == S3E_RESULT_SUCCESS;
}

bool loadInterstitialAd(int adId)
{
    return s3eAmazonAdsLoadInterstitialAd(adId) == S3E_RESULT_SUCCESS;
}

bool showAd(int adId)
{
    return s3eAmazonAdsShowAd(adId) == S3E_RESULT_SUCCESS;
}

bool destroyAd(int adId)
{
    return s3eAmazonAdsDestroyAd(adId) == S3E_RESULT_SUCCESS;
}

bool collapseAd(int adId)
{
    return s3eAmazonAdsCollapseAd(adId) == S3E_RESULT_SUCCESS;
}

bool isLoading(int adId, bool* loading)
{
    s3eAmazonAdsAdInfo info;

    if (s3eAmazonAdsInspectAd(adId, &info) == S3E_RESULT_ERROR)
        return false;
    
    if (info.m_IsLoading)
        *loading=true;
        
    return true;
}

const char* getLastError()
{
    return s3eAmazonAdsGetErrorString();
}

} //namespace Qs3eAmazonAds

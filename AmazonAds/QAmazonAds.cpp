#include "QAmazonAds.h"
#include "s3eAmazonAds.h"
#include "s3eDevice.h"
#include "IwDebug.h"
#include "string.h"

namespace amazonAds {

bool isAvailable()
{
    return s3eAmazonAdsAvailable();
}

bool init(char* androidAppKey, char* iosAppKey, bool enableTesting, bool enableLogging)
{
    if (s3eDeviceGetInt(S3E_DEVICE_OS) == S3E_OS_ID_ANDROID)
    {
        if (!androidAppKey || !androidAppKey[0]) return false;
		return s3eAmazonAdsInit(androidAppKey, enableTesting, enableLogging) == S3E_RESULT_SUCCESS;
    }
	else if (s3eDeviceGetInt(S3E_DEVICE_OS) == S3E_OS_ID_IPHONE)
    {
        if (!iosAppKey || !iosAppKey[0]) return false;
		return s3eAmazonAdsInit(iosAppKey, enableTesting, enableLogging) == S3E_RESULT_SUCCESS;
    }
    else
        return false;
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

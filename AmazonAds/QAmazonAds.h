#ifndef __Q_AMAZONADS_H
#define __Q_AMAZONADS_H

// A Lua wrapper for the s3eAmazonAds C API.
//
// Marmalade intends to update the Quick Ads API to support more ads services
// including Amazon. QAmazonAds is likely to be deprecated for an updated Ads
// library in the future, but for now this provides an easy way to use Amazon
// Ads in Quick.
// Functions behave the same as similarly named C ones in s3eAmazonAds.h
//
// This first commit does not support callbacks/events. In the C version,
// those can be used to tell you when an ad loads and what type of ad was
// presented. Support for events will be added soon.

// tolua_begin

// NB: All bool functions return true on success or false on failure

namespace amazonAds {

bool isAvailable();

bool init(char* androidAppKey, char* iosAppKey, bool enableTesting=true, bool enableLogging=true);
bool terminate();

// returns an integer ad ID or -1 on failure. This should then be passed to
// other functions requiring an "adId" param
int prepareAd();

// positions: "top", "bottom"
// sizes: "custom", "auto"
// if using custom, set width and height
// NB: Amazon supports these standard sizes, so use them via "custom" for best fidelity:
//     "300x50", "320x50", "300x250", "600x90", "728x90", "1024x50"
bool prepareAdLayout(int adId, char* position="top", char* size = "auto", int width = 0, int height = 0);
 
// TODO: get and set targeting options...
 
// if show == false, ad wont show until showAd() is called
// Unlike the C++ sdk, timeout is in seconds, not milliseconds
bool loadAd(int adId, bool show=true, float timeout=20);

// destroy loaded or prepared ad. The ID is no longer valid and resources are freed.
bool destroyAd(int adId);

// Collapse an expanded rich media ad
bool collapseAd(int adId);

// Loads an interstitial ad asynchronously given an ad id.
bool loadInterstitialAd(int adId);

// Show an add previously loaded with loadAd or loadInterstitialAd.
bool showAd(int adId);

// Determine if the given ad is currently loading (false indicated loading finished or
// app has not attempted to load)
// NB: Using soem tolua++ trickery for multiple return type:
//     function take one value (id) and returns two values (bools indicating success/failure
//     and whether its loading): success, loading = amazonAdS:isLoading(id)
bool isLoading(int adId, bool* loading=false);

// Returns a string describing the last error that occurred. If any function above
// fails, call this to find out why. Possible values are string versions of the
// s3eAmazonAdsError enum that is used by the C version of this extension
//  S3E_AMAZONADS_ERR_NONE                      No error.
//  S3E_AMAZONADS_ERR_UNEXPECTED                Unexpected error (unrecoverable runtime/memory error).
//  S3E_AMAZONADS_ERR_INVALID_APPKEY            Application Key validation error (null, non-alphanumeric or length).
//  S3E_AMAZONADS_ERR_INVALID_SIZE              Invalid ad dimensions.
//  S3E_AMAZONADS_ERR_INVALID_OPTION            One or more options are invalid.
//  S3E_AMAZONADS_ERR_NULL_PARAM                NULL pointer exception.
//  S3E_AMAZONADS_ERR_INVALID_ID                Ad identifier is invalid or no longer valid.
//  S3E_AMAZONADS_ERR_INVALID_POSITION          Ad position is invalid.
//  S3E_AMAZONADS_ERR_ALREADY_COLLAPSED         Banner cannot be collapsed as it is not expanded.
//  S3E_AMAZONADS_ERR_CANNOT_COLLAPSE           Ad cannot be collapsed (banner or interstitial).
//  S3E_AMAZONADS_ERR_REGISTRATION_EXCEPTION    App registration error (likely app key error)
//  S3E_AMAZONADS_ERR_BUSY_LOADING              Trying to load when ad is already busy loading.
//  S3E_AMAZONADS_ERR_ID_USED_FOR_INTERSTITIAL  Operation reserved for banners used on id used for interstitials.
//  S3E_AMAZONADS_ERR_NULL_AD                   Operation requires an ad to be loaded, e.g. collapsing an ad.
//  S3E_AMAZONADS_ERR_SHOW_FAILED               An error occurred in trying to show the ad.
//  S3E_AMAZONADS_ERR_ALREADY_SHOWING           Cannot show an ad that is already showing.
//  S3E_AMAZONADS_ERR_NOT_LOADED
const char* getLastError();

}

// tolua_end
#endif // __Q_AMAZONADS_H

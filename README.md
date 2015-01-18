
Note: All the paths here are relative to the root folder of your installed
Marmalade SDK.


Prerequisites
-------------

1. Marmalade SDK 7.4 or newer for the Amazon Mobile Ads extension adn Quick
   improvements. Check for extensions/s3eAmazonAds existing inside your SDK
   install.
   
2. Scripts for rebuilding Quick binaries. Get these from
   https://github.com/nickchops/MarmaladeQuickRebuildScripts Copy those to the
   root quick folder in the SDK.

Two options for where to put the MarmaladeQuickAmazonAds github files:

- Recommended - keep the project in you main github folder. Then, if you
  haven't already, add your github root to global search by putting the
  following in < marmalade-root >/s3e/s3e-default.mkf:

        options { module_paths="path/to/my/github/projects/root" }

  You can do that for each SDK install you have and pick up the same live
  github project in both :)
        
2. Alternatively option - put the files in quick/quickuser. You'll have to
   copy/update each time you update SDK or github.

   
Setup: Add and build this wrapper into Quick
--------------------------------------------

1. Edit quick/quickuser_tolua.pkg and add this new line:

        $cfile "path/to/MarmaladeQuickAmazonAds/QAmazonAds.h"

2. Edit quick/quickuser.mkf and add the following to the 'subprojects' block:

        subprojects
        {
            MarmaladeQuickAmazonAds/QAmazonAds
        }
        
   This allows C++ parts of the actual extension to be built into Quick's
   binaries. If you copied to quick/quickuser, you'll need to prefix with
   the full path to that folder.
   
3. Run quick/quickuser_tolua.bat to generate Lua bindings.

4. Rebuild the Quick binaries by running the scripts (build_quick_prebuilt.bat
   etc.)

   
Using Amazon Ads in your app
----------------------------

1. Add s3eAmazonAds to the 'subprojects' block in your apps .mkb project file.
   This is needed so that platform specific extension libraries (jar, lib etc)
   will be bundled into your app when you deploy it. All ads calls will fail
   if you forget this!

2. Use the Lua APIs in your app! Look in QAmazonAds.h.

The Lua functions match the C++ ones in QAmazonAds.h. The namespace becomes a
table, char* becomes a string, int a number, etc. Make sure you use
amazonAds.xxx() and not amazonAds:xxx()!
   
Quick events are provided to match the C callbacks from s3eAmazonAds.
Quick Amazon Ads uses a single event called "amazonAds" which is registered
with the usual system:addEventListener function. The "type" value of the
table passed to your listener indicates which of the callbacks is being.
The three types are "loaded", "action" and "error".

Example:
   
        myAdId = -1
        
        function adsListener(event)
        {
            if event.type == "loaded" then
                dbg.print("ad with id #" .. event.adId .. " loaded")
                end
            elseif event.type == "action" then
                if event.actionType == "dismissed" then
                    dbg.print("ad with id #" .. event.adId .. " dismissed")
                end
            elseif event.type == "error" then
                dbg.pring("Error loading ad (#" .. event.adId .. "): " .. event.error)
            end
        end

        }
        
        if amazonAds.isAvailable() then
            if amazonAds.init("123456789", "987654321") then
                myAdId = amazonAds.prepareAd()
                
                system:addEventListener("amazonAds", adsListener)

                if myAdId ~= -1 then
                    if amazonAds.prepareAdLayout(myAdId, "bottom") then
                        amazonAds.loadAd(myAdId)
                    end
                end
            end
        end
        
        
See http://docs.madewithmarmalade.com/display/MD/Amazon+Mobile+Ads for further
info inc signing-up for and setting up the ads service online. Check the C++
docs for any known issues or gotchas!


------------------------------------------------------------------------------------------
(C) 2014 Nick Smith.

All code is provided under the MIT license unless stated otherwise:

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.

---
title: Firefox OS 1.3增加WBMP支持
date: 2014-02-27 14:36:59
categories:
  - 开发
tags:
  - Firefox OS
  - WBMP
  - Gecko
---
WBMP是MMS中使用的一种图片格式，在PTCRB认证里面有需求。Mozilla之前在Firefox 1.1中加上过，但后来又去掉了，理由是这格式header太简单，不安全。可是认证没法过这事搞得大家都很纠结。这次这个破事掉到我头上了，没办法，硬着头皮上吧。

首先是找资源，Mozilla自己的Bugzilla上倒是有不少：
  * https://bugzilla.mozilla.org/show_bug.cgi?id=182621
  * https://bugzilla.mozilla.org/show_bug.cgi?id=182621
  * https://bugzilla.mozilla.org/show_bug.cgi?id=847310

可以看出Mozilla纠结的心路旅程。其实要我说，这破事，加上就行了，出错再说。

接下来了解WBMP本身格式，基本上就是0x00开头，接下来Header头，里面几个byte表示宽高，再下面内容是一个bit表示黑白。

最后基本上照着Mozilla的做法改，包括以下几个地方：

  1. gecko/toolkit/content/devicestorage.properties
    修改devicestorage扫描pictures的文件后缀
  2. gecko/netwerk/mime/nsMimeTypes.h
    增加Mime格式：image/vnd.wap.wbmp
  3. gecko/uriloader/exthandler/nsExternalHelperAppService.cpp
    应该是打开图片相关。
  4. 在gecko/image/decoders下增加nsWBMPDecoder.h和nsWBMPDecoder.cpp两个文件
  5. gecko/image/目录下
    src/imgLoader.cpp 这个是打开图片相关，注意加上针对IMG_WBMP第1和第2个byte的检查（第1个是0x00，第2个&0x9f==0）
    src/Image.h，增加eDecoderType_wbmp的定义
    src/Image.cpp，增加GetDecoderType里面WBMP支持
    src/RasterImage.cpp，增加nsWBMPDecoder.h的include，以及生成nsWBMPDecoder对象的代码
    build/nsImageModule.cpp，增加Gecko-Content-Viewers数组元素，但注意不需要加encoder
    decoders/moz.build，增加nsWBMPDecoder.cpp

验证一下，改完收工。

P.S. 这个功能改的一波N折，nsWBMPDecoder先是自己写了一个版本，然后发现根本扫不出来。找到imgLoader里面的WBMP Header头扫描部分，加上后发现decode过程出错，然后发现是没申请内存。加上申请内存之后，发现图片是黑的，基本上判断到解码函数有错。调试过程中发现Mozilla的patch里面有一个1.2的版本应该是可用的，于是把那个版本抽出来了，结果用的时候会卡死。看了Mozilla的patch，解了原算法中的一个bug，结果图片又出错。接下来又发现是数据指针不对，最后是数据指针偏移量算错。最惨是PC的USB接口坏了，耽误了至少两天。就这么个简单问题折腾了一个星期，实在是惭愧。

P.S. Firefox OS 1.3源码更新了一个版本，其中抽象的WriteInternal函数增加了一个参数，所以nsWBMPDecoder中的WriteInternal函数也要修改一下，否则调不到。不过我很奇怪为什么能编译通过，这个没仔细研究了。

{% codeblock nsWBMPDecoder.h lang:cpp %}
/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-               
 *                                                                                         
 * This Source Code Form is subject to the terms of the Mozilla Public                     
 * License, v. 2.0. If a copy of the MPL was not distributed with this                     
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */                             

#ifndef nsWBMPDecoder_h__                                                                  
#define nsWBMPDecoder_h__                                                                  

#include "Decoder.h"                                                                       
#include "nsCOMPtr.h"                                                                      
#include "imgDecoderObserver.h"                                                            
#include "gfxColor.h"                                                                      

namespace mozilla {                                                                        
namespace image {                                                                          
class RasterImage;                                                                         

/* WBMP is a monochrome graphics file format optimized for mobile computing devices.       
 * Format description from http://www.wapforum.org/what/technical/SPEC-WAESpec-19990524.pdf
 */                                                                                        

typedef enum {                                                                             
  WbmpStateStart,                                                                          
  DecodingFixHeader,                                                                       
  DecodingWidth,                                                                           
  DecodingHeight,                                                                          
  DecodingImageData,                                                                       
  DecodingFailed,                                                                          
  WbmpStateFinished                                                                        
} WbmpDecodingState;                                                                       

typedef enum {                                                                             
  IntParseSucceeded,                                                                       
  IntParseFailed,                                                                          
  IntParseInProgress                                                                       
} WbmpIntDecodeStatus;                                                                     

class nsWBMPDecoder : public Decoder                                                       
{                                                                                          
public:                                                                                    

  nsWBMPDecoder(RasterImage &aImage);                       
  virtual ~nsWBMPDecoder();                                                                

  virtual void WriteInternal(const char* aBuffer, uint32_t aCount);                        

private:                                                                                   
  uint32_t mWidth;                                                                         
  uint32_t mHeight;                                                                        

  uint32_t *mImageData;                                                                    

  uint8_t* mRow;                    // Holds one raw line of the image                     
  uint32_t mRowBytes;               // How many bytes of the row were already received     
  uint32_t mCurLine;                // The current line being decoded (0 to mHeight - 1)   

  WbmpDecodingState mState;         // Describes what part of the file we are decoding now.
};                                                                                         

} // namespace image                                                                       
} // namespace mozilla                                                                     

#endif // nsWBMPDecoder_h__                                                                
{% endcodeblock %}

{% codeblock nsWBMPDecoder.cpp lang:cpp %}
/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "nsWBMPDecoder.h"
#include "RasterImage.h"
#include "nspr.h"
#include "nsRect.h"
#include "gfxPlatform.h"

#include "nsError.h"

namespace mozilla {
namespace image {

static inline void SetPixel(uint32_t*& aDecoded, bool aPixelWhite)
{
  uint8_t pixelValue = aPixelWhite ? 255 : 0;

  *aDecoded++ = gfxPackedPixel(0xFF, pixelValue, pixelValue, pixelValue);
}

/** Parses a WBMP encoded int field.  Returns IntParseInProgress (out of
 *  data), IntParseSucceeded if the field was read OK or IntParseFailed
 *  on an error.
 *  The encoding used for WBMP ints is per byte.  The high bit is a
 *  continuation flag saying (when set) that the next byte is part of the
 *  field, and the low seven bits are data.  New data bits are added in the
 *  low bit positions, i.e. the field is big-endian (ignoring the high bits).
 * @param aField Variable holds current value of field.  When this function
 *               returns IntParseInProgress, aField will hold the
 *               intermediate result of the decoding, so this function can be
 *               called repeatedly for new bytes on the same field and will
 *               operate correctly.
 * @param aBuffer Points to encoded field data.
 * @param aCount Number of bytes in aBuffer. */
static WbmpIntDecodeStatus DecodeEncodedInt (uint32_t& aField, const char*& aBuffer, uint32_t& aCount)
{
  while (aCount > 0) {
    // Check if the result would overflow if another seven bits were added.
    // The actual test performed is AND to check if any of the top seven bits are set.
    if (aField & 0xFE000000) {
      // Overflow :(
      return IntParseFailed;
    }

    // Get next encoded byte.
    char encodedByte = *aBuffer;

    // Update buffer state variables now we have read this byte.
    aBuffer++;
    aCount--;

    // Work out and store the new (valid) value of the encoded int with this byte added.
    aField = (aField << 7) + (uint32_t)(encodedByte & 0x7F);

    if (!(encodedByte & 0x80)) {
      // No more bytes, value is complete.
      return IntParseSucceeded;
    }
  }

  // Out of data but in the middle of an encoded int.
  return IntParseInProgress;
}

nsWBMPDecoder::nsWBMPDecoder(RasterImage &aImage)
 : Decoder(aImage),
   mWidth(0),
   mHeight(0),
   mImageData(nullptr),
   mRow(nullptr),
   mRowBytes(0),
   mCurLine(0),
   mState(WbmpStateStart)
{
  // Nothing to do
}

nsWBMPDecoder::~nsWBMPDecoder()
{
  moz_free(mRow);
}

void
nsWBMPDecoder::WriteInternal(const char *aBuffer, uint32_t aCount)
{
  NS_ABORT_IF_FALSE(!HasError(), "Shouldn't call WriteInternal after error!");

  // Loop until the input data is gone
  while (aCount > 0) {
    switch (mState) {
      case WbmpStateStart:
      {
        // Since we only accept a type 0 WBMP we can just check the first byte is 0.
        // (The specification says a well defined type 0 bitmap will start with a 0x00 byte).
        if (*aBuffer++ == 0x00) {
          // This is a type 0 WBMP.
          aCount--;
          mState = DecodingFixHeader;
        } else {
          // This is a new type of WBMP or a type 0 WBMP defined oddly (e.g. 0x80 0x00)
          PostDataError();
          mState = DecodingFailed;
          return;
        }
        break;
      }

      case DecodingFixHeader:
      {
        if ((*aBuffer++ & 0x9F) == 0x00) {
          // Fix header field is as expected
          aCount--;
          // For now, we skip the ext header field as it is not in a well-defined type 0 WBMP.
          mState = DecodingWidth;
        } else {
          // Can't handle this fix header field.
          PostDataError();
          mState = DecodingFailed;
          return;
        }
        break;
      }

      case DecodingWidth:
      {
        WbmpIntDecodeStatus widthReadResult = DecodeEncodedInt (mWidth, aBuffer, aCount);

        if (widthReadResult == IntParseSucceeded) {
          mState = DecodingHeight;
        } else if (widthReadResult == IntParseFailed) {
          // Encoded width was bigger than a uint32_t or equal to 0.
          PostDataError();
          mState = DecodingFailed;
          return;
        } else {
          // We are still parsing the encoded int field.
          NS_ABORT_IF_FALSE((widthReadResult == IntParseInProgress),
                            "nsWBMPDecoder got bad result from an encoded width field");
          return;
        }
        break;
      }

      case DecodingHeight:
      {
        WbmpIntDecodeStatus heightReadResult = DecodeEncodedInt (mHeight, aBuffer, aCount);

        if (heightReadResult == IntParseSucceeded) {
          // The header has now been entirely read.
          const uint32_t k64KWidth = 0x0000FFFF;
          if (mWidth == 0 || mWidth > k64KWidth
              || mHeight == 0 || mHeight > k64KWidth) {
            // consider 0 as an incorrect image size
            // reject the extremely wide/high images to keep the math sane
            PostDataError();
            mState = DecodingFailed;
            return;
          }

          // Post our size to the superclass
          PostSize(mWidth, mHeight);
          if (HasError()) {
            // Setting the size led to an error.
            mState = DecodingFailed;
            return;
          }

          // If We're doing a size decode, we're done
          if (IsSizeDecode()) {
            mState = WbmpStateFinished;
            return;
          }

          uint32_t imageLength;
          // Add the frame and signal
          imgFrame* frame = nullptr;
          nsresult rv = mImage.EnsureFrame(0, 0, 0, mWidth, mHeight,
                                            gfxImageFormatRGB24,
                                           (uint8_t**)&mImageData,
                                            &imageLength ,&frame);

          if (NS_FAILED(rv) || !mImageData) {
            PostDecoderError(NS_ERROR_FAILURE);
            mState = DecodingFailed;
            return;
          }

          // Create mRow, the buffer that holds one line of the raw image data
          mRow = (uint8_t*)moz_malloc((mWidth + 7) / 8);
          if (!mRow) {
            PostDecoderError(NS_ERROR_OUT_OF_MEMORY);
            mState = DecodingFailed;
            return;
          }

          // Tell the superclass we're starting a frame
          PostFrameStart();

          mState = DecodingImageData;

        } else if (heightReadResult == IntParseFailed) {
          // Encoded height was bigger than a uint32_t.
          PostDataError();
          mState = DecodingFailed;
          return;
        } else {
          // We are still parsing the encoded int field.
          NS_ABORT_IF_FALSE((heightReadResult == IntParseInProgress),
                            "nsWBMPDecoder got bad result from an encoded height field");
          return;
        }
        break;
      }

      case DecodingImageData:
      {
        uint32_t rowSize = (mWidth + 7) / 8; // +7 to round up to nearest byte
        uint32_t top = mCurLine;

        // Process up to one row of data at a time until there is no more data.
        while ((aCount > 0) && (mCurLine < mHeight)) {
          // Calculate if we need to copy data to fill the next buffered row of raw data.
          uint32_t toCopy = rowSize - mRowBytes;

          // If required, copy raw data to fill a buffered row of raw data.
          if (toCopy) {
            if (toCopy > aCount)
              toCopy = aCount;
            memcpy(mRow + mRowBytes, aBuffer, toCopy);
            aCount -= toCopy;
            aBuffer += toCopy;
            mRowBytes += toCopy;
          }

          // If there is a filled buffered row of raw data, process the row.
          if (rowSize == mRowBytes) {
            uint8_t *p = mRow;
            uint32_t *d = mImageData + (mWidth * mCurLine); // position of the first pixel at mCurLine
            uint32_t lpos = 0;

            while (lpos < mWidth) {
              for (int8_t bit = 7; bit >= 0; bit--) {
                if (lpos >= mWidth)
                  break;
                bool pixelWhite = (*p >> bit) & 1;
                SetPixel(d, pixelWhite);
                ++lpos;
              }
              ++p;
            }

            mCurLine++;
            mRowBytes = 0;
          }
        }

        nsIntRect r(0, top, mWidth, mCurLine - top);
        // Invalidate
        PostInvalidation(r);

        // If we've got all the pixel bytes, we're finished
        if (mCurLine == mHeight) {
          PostFrameStop();
          PostDecodeDone();
          mState = WbmpStateFinished;
        }
        break;
      }

      case WbmpStateFinished:
      {
        // Consume all excess data silently
        aCount = 0;
        break;
      }

      case DecodingFailed:
      {
        NS_ABORT_IF_FALSE(0, "Shouldn't process any data after decode failed!");
        return;
      }
    }
  }
}

} // namespace image
} // namespace mozilla
{% endcodeblock %}

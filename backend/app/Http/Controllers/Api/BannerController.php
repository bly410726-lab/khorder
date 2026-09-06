<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class BannerController extends Controller
{
    /**
     * Customer: Get active banners only.
     */
    public function index()
    {
        $banners = Banner::active()
            ->ordered()
            ->get()
            ->map(fn($banner) => [
                'id' => $banner->id,
                'title' => $banner->title,
                'image' => $banner->image_url,
                'is_active' => $banner->is_active,
                'sort_order' => $banner->sort_order,
            ]);

        return response()->json([
            'success' => true,
            'data' => $banners,
        ]);
    }
}

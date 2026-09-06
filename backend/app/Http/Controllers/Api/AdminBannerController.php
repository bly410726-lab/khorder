<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class AdminBannerController extends Controller
{
    /**
     * Admin: Get all banners.
     */
    public function index()
    {
        $banners = Banner::orderBy('sort_order', 'asc')
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

    /**
     * Admin: Create a new banner with image upload.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'image' => 'required|image|mimes:jpeg,jpg,png,webp,gif|max:5120',
            'title' => 'nullable|string|max:255',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer|min:0',
        ]);

        $image = $request->file('image');
        $filename = 'banner_' . Str::uuid() . '.' . $image->getClientOriginalExtension();
        $path = $image->storeAs('banners', $filename, 'public');

        $banner = Banner::create([
            'title' => $validated['title'] ?? null,
            'image' => $path,
            'is_active' => $validated['is_active'] ?? true,
            'sort_order' => $validated['sort_order'] ?? 0,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Banner created successfully.',
            'data' => [
                'id' => $banner->id,
                'title' => $banner->title,
                'image' => $banner->image_url,
                'is_active' => $banner->is_active,
                'sort_order' => $banner->sort_order,
            ],
        ], 201);
    }

    /**
     * Admin: Update a banner.
     */
    public function update(Request $request, int $id)
    {
        $banner = Banner::findOrFail($id);

        $validated = $request->validate([
            'image' => 'nullable|image|mimes:jpeg,jpg,png,webp,gif|max:5120',
            'title' => 'nullable|string|max:255',
            'is_active' => 'nullable|boolean',
            'sort_order' => 'nullable|integer|min:0',
        ]);

        if ($request->hasFile('image')) {
            // Delete old image
            if ($banner->image && Storage::disk('public')->exists($banner->image)) {
                Storage::disk('public')->delete($banner->image);
            }

            $image = $request->file('image');
            $filename = 'banner_' . Str::uuid() . '.' . $image->getClientOriginalExtension();
            $path = $image->storeAs('banners', $filename, 'public');
            $banner->image = $path;
        }

        if ($request->has('title')) {
            $banner->title = $validated['title'];
        }
        if ($request->has('is_active')) {
            $banner->is_active = $validated['is_active'];
        }
        if ($request->has('sort_order')) {
            $banner->sort_order = $validated['sort_order'];
        }

        $banner->save();

        return response()->json([
            'success' => true,
            'message' => 'Banner updated successfully.',
            'data' => [
                'id' => $banner->id,
                'title' => $banner->title,
                'image' => $banner->image_url,
                'is_active' => $banner->is_active,
                'sort_order' => $banner->sort_order,
            ],
        ]);
    }

    /**
     * Admin: Delete a banner and its image.
     */
    public function destroy(int $id)
    {
        $banner = Banner::findOrFail($id);

        // Delete stored image
        if ($banner->image && Storage::disk('public')->exists($banner->image)) {
            Storage::disk('public')->delete($banner->image);
        }

        $banner->delete();

        return response()->json([
            'success' => true,
            'message' => 'Banner deleted successfully.',
        ]);
    }
}

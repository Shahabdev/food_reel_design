Add-Type -AssemblyName System.Drawing

$csharp = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections.Generic;

public class TransparentPngConverter
{
    public static void ConvertToTransparentPng(string inputJpgPath, string outputPngPath)
    {
        using (Bitmap src = new Bitmap(inputJpgPath))
        {
            int w = src.Width;
            int h = src.Height;
            Bitmap dst = new Bitmap(w, h, PixelFormat.Format32bppArgb);

            BitmapData srcData = src.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            BitmapData dstData = dst.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);

            int stride = srcData.Stride;
            byte[] srcBytes = new byte[stride * h];
            byte[] dstBytes = new byte[stride * h];
            System.Runtime.InteropServices.Marshal.Copy(srcData.Scan0, srcBytes, 0, srcBytes.Length);
            Array.Copy(srcBytes, dstBytes, srcBytes.Length);

            bool[] visited = new bool[w * h];
            Queue<int> queue = new Queue<int>();

            // Seed with all boundary pixels
            for (int x = 0; x < w; x++)
            {
                queue.Enqueue(x);
                visited[x] = true;
                queue.Enqueue((h - 1) * w + x);
                visited[(h - 1) * w + x] = true;
            }
            for (int y = 0; y < h; y++)
            {
                if (!visited[y * w]) { queue.Enqueue(y * w); visited[y * w] = true; }
                if (!visited[y * w + (w - 1)]) { queue.Enqueue(y * w + (w - 1)); visited[y * w + (w - 1)] = true; }
            }

            int[] dx = { 0, 0, 1, -1 };
            int[] dy = { 1, -1, 0, 0 };

            while (queue.Count > 0)
            {
                int curr = queue.Dequeue();
                int cy = curr / w;
                int cx = curr % w;
                int idx = cy * stride + cx * 4;

                // 100% transparent
                dstBytes[idx] = 0;     // B
                dstBytes[idx + 1] = 0; // G
                dstBytes[idx + 2] = 0; // R
                dstBytes[idx + 3] = 0; // A = 0 (Transparent!)

                for (int i = 0; i < 4; i++)
                {
                    int nx = cx + dx[i];
                    int ny = cy + dy[i];
                    if (nx >= 0 && nx < w && ny >= 0 && ny < h)
                    {
                        int npos = ny * w + nx;
                        if (!visited[npos])
                        {
                            int nidx = ny * stride + nx * 4;
                            byte nb = srcBytes[nidx];
                            byte ng = srcBytes[nidx + 1];
                            byte nr = srcBytes[nidx + 2];

                            // All background pixels are pure 255 or near 255
                            int minChan = Math.Min(nr, Math.Min(ng, nb));
                            int maxDiff = Math.Max(Math.Abs(nr - ng), Math.Max(Math.Abs(ng - nb), Math.Abs(nr - nb)));

                            if (minChan >= 235 && maxDiff <= 25)
                            {
                                visited[npos] = true;
                                queue.Enqueue(npos);
                            }
                        }
                    }
                }
            }

            // Anti-aliased edge smoothing: if a pixel borders a transparent pixel and is very light, fade its alpha
            for (int y = 1; y < h - 1; y++)
            {
                for (int x = 1; x < w - 1; x++)
                {
                    int npos = y * w + x;
                    if (!visited[npos])
                    {
                        bool bordersTransparent = visited[(y - 1) * w + x] || visited[(y + 1) * w + x] || visited[y * w + (x - 1)] || visited[y * w + (x + 1)];
                        if (bordersTransparent)
                        {
                            int idx = y * stride + x * 4;
                            byte nb = dstBytes[idx];
                            byte ng = dstBytes[idx + 1];
                            byte nr = dstBytes[idx + 2];
                            int minChan = Math.Min(nr, Math.Min(ng, nb));
                            if (minChan > 220)
                            {
                                // Partially transparent edge for smooth blending
                                double factor = (255.0 - minChan) / 35.0;
                                dstBytes[idx + 3] = (byte)(Math.Max(0.0, Math.Min(1.0, factor)) * 255);
                            }
                        }
                    }
                }
            }

            System.Runtime.InteropServices.Marshal.Copy(dstBytes, 0, dstData.Scan0, dstBytes.Length);
            src.UnlockBits(srcData);
            dst.UnlockBits(dstData);

            dst.Save(outputPngPath, ImageFormat.Png);
            dst.Dispose();
        }
    }
}
"@

Add-Type -TypeDefinition $csharp -ReferencedAssemblies "System.Drawing"

$items = @("noodles", "pizza", "burger", "skewers", "cat_all", "cat_drinks", "cat_food", "cat_fruits", "cat_snack")
foreach ($it in $items) {
    $src = "assets\images\$it.jpg"
    $dst = "assets\images\$it.png"
    if (Test-Path $src) {
        Write-Output "Converting $it to transparent PNG..."
        [TransparentPngConverter]::ConvertToTransparentPng((Resolve-Path $src).Path, (Resolve-Path "assets\images").Path + "\$it.png")
        Write-Output "Created $dst"
    }
}
Write-Output "ALL IMAGES SUCCESSFULLY CONVERTED TO TRANSPARENT PNGs!"

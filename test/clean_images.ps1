Add-Type -AssemblyName System.Drawing

$csharp = @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Collections.Generic;

public class ImageCleanerBatch
{
    public static void CleanBackground(string inputPath, string outputPath)
    {
        using (Bitmap src = new Bitmap(inputPath))
        {
            int w = src.Width;
            int h = src.Height;
            Bitmap dst = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            
            BitmapData srcData = src.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            BitmapData dstData = dst.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.WriteOnly, PixelFormat.Format32bppArgb);

            int stride = srcData.Stride;
            int bytesPerPixel = 4;
            byte[] srcBytes = new byte[stride * h];
            byte[] dstBytes = new byte[stride * h];
            System.Runtime.InteropServices.Marshal.Copy(srcData.Scan0, srcBytes, 0, srcBytes.Length);
            Array.Copy(srcBytes, dstBytes, srcBytes.Length);

            bool[] visited = new bool[w * h];
            Queue<int> queue = new Queue<int>();

            // Seed with all border pixels
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
                int idx = cy * stride + cx * bytesPerPixel;

                dstBytes[idx] = 255;
                dstBytes[idx + 1] = 255;
                dstBytes[idx + 2] = 255;
                dstBytes[idx + 3] = 255;

                for (int i = 0; i < 4; i++)
                {
                    int nx = cx + dx[i];
                    int ny = cy + dy[i];
                    if (nx >= 0 && nx < w && ny >= 0 && ny < h)
                    {
                        int npos = ny * w + nx;
                        if (!visited[npos])
                        {
                            int nidx = ny * stride + nx * bytesPerPixel;
                            byte nb = srcBytes[nidx];
                            byte ng = srcBytes[nidx + 1];
                            byte nr = srcBytes[nidx + 2];

                            int maxDiff = Math.Max(Math.Abs(nr - ng), Math.Max(Math.Abs(ng - nb), Math.Abs(nr - nb)));
                            int minChan = Math.Min(nr, Math.Min(ng, nb));

                            if (minChan >= 210 && maxDiff <= 35)
                            {
                                visited[npos] = true;
                                queue.Enqueue(npos);
                            }
                        }
                    }
                }
            }

            System.Runtime.InteropServices.Marshal.Copy(dstBytes, 0, dstData.Scan0, dstBytes.Length);
            src.UnlockBits(srcData);
            dst.UnlockBits(dstData);

            ImageCodecInfo jpgEncoder = null;
            foreach (ImageCodecInfo codec in ImageCodecInfo.GetImageEncoders())
            {
                if (codec.FormatID == ImageFormat.Jpeg.Guid) { jpgEncoder = codec; break; }
            }
            EncoderParameters encParams = new EncoderParameters(1);
            encParams.Param[0] = new EncoderParameter(Encoder.Quality, 98L);
            dst.Save(outputPath, jpgEncoder, encParams);
            dst.Dispose();
        }
    }
}
"@

Add-Type -TypeDefinition $csharp -ReferencedAssemblies "System.Drawing"

$items = @("cat_all", "cat_drinks", "cat_food", "cat_fruits", "cat_snack", "skewers", "pizza", "noodles", "burger")
foreach ($it in $items) {
    $src = "assets\images\$it.jpg"
    $tmp = "assets\images\${it}_tmp.jpg"
    if (Test-Path $src) {
        Write-Output "Processing $it..."
        [ImageCleanerBatch]::CleanBackground((Resolve-Path $src).Path, (Resolve-Path "assets\images").Path + "\${it}_tmp.jpg")
        # Replace original
        Remove-Item $src -Force
        Move-Item $tmp $src -Force
        Write-Output "Finished $it"
    }
}
Write-Output "ALL IMAGES SUCCESSFULLY CLEANED TO PURE WHITE!"

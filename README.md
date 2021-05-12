## Making a cross-stitch pattern

I wrote several R functions that takes an image and create a cross-stitch pattern. 
_Note_: This includes thread colour.

### Objective
- I used clustering to simplify the image because most images have too many colours to conveniently cross-stitch. 
- Not every colour has an associated embroidery floss colour, so the `dmc` pacakge was used for finding the nearest thread to a given colour.
-  I made the user select how many threads they will use. 
-  Most images have too many pixels to make a realistic cross-stitch. I used the function `change_resolution` to change the resolution of an image in `(x, y, cluster)`. The lower resolution image uses the most common colour in the pixels that are being combined to get the aggregate colour. _Note_: Sometimes this function drops a small cluster because it is never the most common cluster. This is not an error. 
-  I made an `actual pattern` that people can use to do cross-stitch.
-  Some images have background colours that do not need to be covered in stitches. My code allowed for one of the clusters to be "background" and those entries in the pattern became empty. 

### Example
We will use a picture of Marilyn Monroe. The following is the original image of Marilyn Monroe.  

![unnamed-chunk-3-1](https://user-images.githubusercontent.com/71662106/117996191-f0c11880-b30f-11eb-89f8-814a1378b48a.png)

Below is an example of a Marilyn Monroe cross-stitch. One is in colour and the other is in black and white. Both use symbols to differentiate colours and grid lines to help read the pattern. The legend has both the name of the colour and the colour number. The clustering that was used to make this pattern had 7 clusters, but after reducting the resolution, two of these clusters did not appear in the final picture.  

![unnamed-chunk-11-1](https://user-images.githubusercontent.com/71662106/117995894-b0619a80-b30f-11eb-809e-3ec77bc78cbc.png)

![unnamed-chunk-15-1](https://user-images.githubusercontent.com/71662106/117996051-d1c28680-b30f-11eb-87da-ba2d9ff0ec88.png)

### Contraints
- The image should not be too high-resolution.
- Not every picture will make a good cross-stitch. It works best if there is just one main focus of the picture and not too many background. 

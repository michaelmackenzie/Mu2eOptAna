# Mu2e optimization analysis

Code to evaluate optimization metrics.

## Building
```bash
mu2einit
muse backing SimJob Run1Baq
git clone https://github.com/michaelmackenzie/Mu2eOptAna.git
git clone https://github.com/Mu2e/Mu2eBO.git --branch ExtractAna
# on build02
muse build --mu2eCompactPrint --mu2ePyWrap --mu2eCBD -j4 
```

Make a tarball:
```bash
muse tarball
```
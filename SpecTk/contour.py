#!/usr/bin/env python
# coding: utf-8

# In[ ]:
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import contour
from scipy.stats import chi2

with open("data.txt", "r") as f:
    lines = f.readlines()

curve_type = lines[0].strip()
params = list(map(float, lines[1].split()))
percent = float(lines[2].strip())

points = []

if curve_type == "2D Gaussian":
    A, x0, y0, sigx, sigy, theta, B = params
    scale = np.sqrt(chi2.ppf(percent / 100.0, df=2))
    sigx *= scale
    sigy *= scale
    t = np.linspace(0, 2*np.pi, 100)
    cost, sint = np.cos(theta), np.sin(theta)
    for angle in t:
        ct, st = np.cos(angle), np.sin(angle)
        x = x0 + sigx * ct * cost - sigy * st * sint
        y = y0 + sigx * ct * sint + sigy * st * cost
        points.append((x, y))

elif curve_type == "2D Polynomial":
    A, B, C, D, E, F = params

    x = np.linspace(-50, 50, 300)
    y = np.linspace(-50, 50, 300)
    X, Y = np.meshgrid(x, y)

    Z = A*X**2 + B*X*Y + C*Y**2 + D*X + E*Y + F
    Z[Z <= 0] = np.nan


    percent = 100-percent
    Zmax = np.nanmax(Z)
    Zlevel = percent / 100.0 * Zmax

    fig, ax = plt.subplots()
    CS = ax.contour(X, Y, Z, levels=[Zlevel])
    plt.close(fig)

    for c in CS.collections[0].get_paths():
        v = c.vertices
        for xval, yval in v:
            points.append((xval, yval))

elif curve_type == "Ellipse":
    x0, y0, a, b, c, theta = params

    scale = np.sqrt(percent / 100.0)

    t = np.linspace(0, 2*np.pi, 100)
    for angle in t:
        x_ = scale * a * np.cos(angle)
        y_ = scale * b * np.sin(angle)
        x = x0 + x_ * np.cos(theta) - y_ * np.sin(theta)
        y = y0 + x_ * np.sin(theta) + y_ * np.cos(theta)
        points.append((x, y))


elif curve_type == "EllipseMoment":
    x0, y0, a, b, theta = params

    t = np.linspace(0, 2*np.pi, 100)
    for angle in t:
        x_ = a * np.cos(angle)
        y_ = b * np.sin(angle)
        x = x0 + x_ * np.cos(theta) - y_ * np.sin(theta)
        y = y0 + x_ * np.sin(theta) + y_ * np.cos(theta)
        points.append((x, y))

with open("contour.txt", "w") as f:
    for x, y in points:
        f.write(f"{x} {y}\n")

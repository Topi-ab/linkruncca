import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Ellipse

def ellipse_from_sums_md(Sx, Sy, Sxy, Sxx, Syy, N):
    # 1. Centroid
    xc = Sx / N
    yc = Sy / N

    # 2. Central second moments
    mu20 = Sxx / N - xc**2
    mu02 = Syy / N - yc**2
    mu11 = Sxy / N - xc * yc

    # 4. Eigenvalues 
    t_half = 0.5 * (mu20 + mu02)
    discriminator = ((mu20 - mu02) / 2.0)**2 + mu11**2
    root = np.sqrt(discriminator)

    lam1 = t_half + root
    lam2 = t_half - root
    if lam2 > lam1:
        lam1, lam2 = lam2, lam1

    # 5. Axis lengths
    major_diam = 2.0 * np.sqrt(max(lam1, 0.0))
    minor_diam = 2.0 * np.sqrt(max(lam2, 0.0))

    # 6. Orientation
    angle_rad = 0.5 * np.arctan2(2.0 * mu11, mu20 - mu02)

    return xc, yc, major_diam, minor_diam, angle_rad

def sums_from_points(points):
    x = points[:, 0]
    y = points[:, 1]
    return np.sum(x), np.sum(y), np.sum(x*y), np.sum(x*x), np.sum(y*y), len(points)

def generate_points_in_ellipse(center, a, b, angle_rad, n_points=300, seed=None):
    rng = np.random.default_rng(seed)
    t = 2 * np.pi * rng.random(n_points)
    r = np.sqrt(rng.random(n_points))
    X = a * r * np.cos(t)
    Y = b * r * np.sin(t)
    R = np.array([[np.cos(angle_rad), -np.sin(angle_rad)],
                  [np.sin(angle_rad),  np.cos(angle_rad)]])
    pts = np.column_stack((X, Y)) @ R.T + np.array(center)
    return pts

def plot_datasets_with_ellipses(datasets, colors=None, contour_colors=None):
    if colors is None:
        colors = ["tab:blue", "tab:orange", "tab:green"]
    if contour_colors is None:
        contour_colors = colors

    fig, ax = plt.subplots()
    for i, pts in enumerate(datasets):
        c = colors[i % len(colors)]
        cc = contour_colors[i % len(colors)]
        ax.scatter(pts[:, 0], pts[:, 1], s=10, alpha=0.7, color=c, label=f"Dataset {i+1}")

        Sx, Sy, Sxy, Sxx, Syy, N = sums_from_points(pts)
        xc, yc, major, minor, ang = ellipse_from_sums_md(Sx, Sy, Sxy, Sxx, Syy, N)

        e = Ellipse((xc, yc), width=major, height=minor,
                    angle=np.degrees(ang), fill=False, lw=2, ec=cc)
        ax.add_patch(e)

        print(f"Dataset {i+1}: center=({xc:.2f}, {yc:.2f}), "
              f"major={major:.2f}, minor={minor:.2f}, angle={np.degrees(ang):.2f}°")

    ax.set_aspect('equal', adjustable='box')
    ax.set_title("Ellipse fit from hardware-style collected sums (MD exact)")
    ax.grid(True)
    ax.legend()
    plt.show()

# Generate example datasets
ds1 = generate_points_in_ellipse(center=(0, 0),   a=5, b=2.5, angle_rad=np.radians(30), n_points=400, seed=1)
ds2 = generate_points_in_ellipse(center=(12, 3),  a=3, b=1.2, angle_rad=np.radians(-20), n_points=350, seed=2)
ds3 = generate_points_in_ellipse(center=(-8, 7),  a=4, b=3.5, angle_rad=np.radians(70), n_points=300, seed=3)

plot_datasets_with_ellipses([ds1, ds2, ds3], colors=["red", "green", "blue"], contour_colors=["green", "blue", "red"])

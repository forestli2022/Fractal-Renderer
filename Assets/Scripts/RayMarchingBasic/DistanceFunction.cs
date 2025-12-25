using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class DistanceFunction
{
    // operations
    // absolute value of a vector3
    public static Vector3 abs(Vector3 a)
    {
        return new Vector3(Mathf.Abs(a[0]), Mathf.Abs(a[1]), Mathf.Abs(a[2]));
    }

    // max of each vector
    public static Vector3 max(Vector3 a, Vector3 b)
    {
        return new Vector3(Mathf.Max(a.x, b.x), Mathf.Max(a.y, b.y), Mathf.Max(a.z, b.z));
    }


    // Plane
    public static float sdPlane(Vector3 p, Vector3 n, float h)
    {
        // n must be normalized
        return Vector3.Dot(p, n) + h;
    }

    // Sphere
    // s: radius
    public static float sdSphere(Vector3 p, float s)
    {
        return p.magnitude - s;
    }

    // Box
    // b: size of box in x/y/z
    public static float sdBox(Vector3 p, Vector3 b)
    {
        Vector3 d = abs(p) - b;
        return Mathf.Min(Mathf.Max(d.x, Mathf.Max(d.y, d.z)), 0f) + max(d, Vector3.zero).magnitude;
    }

    // InfBox
    // b: size of box in x/y/z
    public static float sd2DBox(in Vector2 p, in Vector2 b)
    {
        Vector2 d = new Vector2(Mathf.Abs(p.x) - b.x, Mathf.Abs(p.y) - b.y);
        return new Vector2(Mathf.Max(d.x, 0), Mathf.Max(d.y, 0)).magnitude + Mathf.Min(Mathf.Max(d.x, d.y), 0f);
    }

    // Cross
    public static float sdCross(in Vector3 p, float b)
    {
        float da = sd2DBox(new Vector2(p.x, p.y), new Vector2(b, b));
        float db = sd2DBox(new Vector2(p.y, p.z), new Vector2(b, b));
        float dc = sd2DBox(new Vector2(p.z, p.x), new Vector2(b, b));
        return Mathf.Min(da, Mathf.Min(db, dc));
    }

    // Mandelbulb
    public static float Mandelbulb(Vector3 pos, int Iterations, float Bailout, float Power)
    {
        Vector3 z = pos;
        float dr = 1f;
        float r = 0;
        for (int i = 0; i < Iterations; i++)
        {
            r = z.magnitude;
            if (r > Bailout) break;

            // convert to polar coordinates
            float theta = Mathf.Acos(z.z / r);
            float phi = Mathf.Atan(z.y / z.x);
            dr = (Mathf.Pow(r, Power - 1f) * Power * dr) + 1.0f;

            // scale and rotate the point
            float zr = Mathf.Pow(r, Power);
            theta = theta * Power;
            phi = phi * Power;

            // convert back to cartesian coordinates
            z = zr * new Vector3(Mathf.Sin(theta) * Mathf.Cos(phi), Mathf.Sin(phi) * Mathf.Sin(theta), Mathf.Cos(theta));
            z += pos;
        }
        return 0.5f * Mathf.Log(r) * r / dr;
    }

    // MengerSponge
    public static float MengerSponge(Vector3 p, float b, int iteration)
    {
        p.x = Mathf.Abs(p.x);
        p.y = Mathf.Abs(p.y);
        p.z = Mathf.Abs(p.z);
        float d = sdBox(p, new Vector3(b, b, b));
        float s = 1f / b;
        for (int m = 0; m < iteration; m++)
        {
            Vector3 a = new Vector3((p.x * s) % 2f - 1f, (p.y * s) % 2f - 1f, (p.z * s) % 2f - 1f);
            s *= 3f;
            Vector3 r = new Vector3(Mathf.Abs(1 - 3 * Mathf.Abs(a.x)), Mathf.Abs(1 - 3 * Mathf.Abs(a.y)), Mathf.Abs(1 - 3 * Mathf.Abs(a.z)));
            float c = sdCross(r, 1) / s;
            d = Mathf.Max(d, c);
        }

        return d;
    }

    // BOOLEAN OPERATORS //

    // Union
    public static float opU(float d1, float d2)
    {
        return Mathf.Min(d1, d2);
    }

    public static float opSmoothUnion(float d1, float d2, float k)
    {
        float h = Mathf.Clamp(0.5f + 0.5f * (d2 - d1) / k, 0, 1);
        return Mathf.Lerp(d2, d1, h) - k * h * (1.0f - h);
    }

    // Subtraction
    public static float opS(float d1, float d2)
    {
        return Mathf.Max(-d1, d2);
    }

    // Intersection
    public static float opI(float d1, float d2)
    {
        return Mathf.Max(d1, d2);
    }

    // Mod Position Axis
    public static float pMod1(float p, float size)
    {
        float halfsize = size / 2;
        p = (p + halfsize) % size - halfsize;
        p = (p - halfsize) % size + halfsize;
        return p;
    }
}

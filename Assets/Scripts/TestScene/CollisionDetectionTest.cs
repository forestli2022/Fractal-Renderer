using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CollisionDetectionTest : CollisionDetection
{
    public RaymarchCamera cam;

    Vector3 RotateY(Vector3 v, float degree)
    {
        float rad = 0.0174532925f * degree;
        float cosY = Mathf.Cos(rad);
        float sinY = Mathf.Sin(rad);
        return new Vector3(cosY * v.x - sinY * v.z, v.y, sinY * v.x + cosY * v.z);
    }

    protected override float GetDistance(Vector3 p)
    {
        float plane = DistanceFunction.sdPlane(p, new Vector3(0, 1, 0), 0);
        Vector3 spherePos = new Vector3(cam._sphere.x, cam._sphere.y, cam._sphere.z);
        float sphere = DistanceFunction.sdSphere(p - spherePos, cam._sphere.w);
        for (int i = 1; i < 8; i++)
        {
            float sphereAdd = DistanceFunction.sdSphere(RotateY(p, cam._degreeRotate * i) - spherePos, cam._sphere.w);
            sphere = DistanceFunction.opSmoothUnion(sphere, sphereAdd, cam._sphereSmooth);
        }
        return DistanceFunction.opSmoothUnion(sphere, plane, cam._sphereSmooth);
    }
}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CollisionDetection : MonoBehaviour
{
    public float radius = 1;
    private Rigidbody rb;

    // Start is called before the first frame update
    protected virtual void Start()
    {
        rb = GetComponent<Rigidbody>();
    }

    // Update is called once per frame
    protected virtual void Update()
    {
        float d = GetDistance(transform.position);
        if (d < radius)
        {
            Vector3 n = GetNormal(transform.position);
            transform.position += n * (radius - d);
            print(n);
            rb.AddForce(n, ForceMode.Impulse);
        }
    }

    protected virtual float GetDistance(Vector3 p)
    {
        print("Function GetDistance needs to be overriden");
        return 1;
    }

    protected virtual Vector3 GetNormal(Vector3 p)
    {
        Vector2 offset = new Vector2(0.01f, 0.0f);
        Vector3 x = new Vector3(0.01f, 0, 0);
        Vector3 y = new Vector3(0, 0.01f, 0);
        Vector3 z = new Vector3(0, 0, 0.01f);
        Vector3 n = new Vector3(
        GetDistance(p + x) - GetDistance(p - x),
        GetDistance(p + y) - GetDistance(p - y),
        GetDistance(p + z) - GetDistance(p - z));
        return n.normalized;
    }
}
